import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/isar_service.dart';
import '../../data/models/lost_item_model.dart';
import '../../domain/usecases/claim_item_usecase.dart';
import '../../domain/usecases/post_lost_item_usecase.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class LostFoundEvent extends Equatable {
  const LostFoundEvent();
  @override
  List<Object?> get props => [];
}

final class LoadItemsRequested extends LostFoundEvent {
  const LoadItemsRequested();
}

final class PostItemRequested extends LostFoundEvent {
  final String title;
  final String description;
  final String imagePath;
  final String location;
  const PostItemRequested({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.location,
  });
  @override
  List<Object?> get props => [title, description, imagePath, location];
}

final class ClaimItemRequested extends LostFoundEvent {
  final LostItemModel item;
  const ClaimItemRequested({required this.item});
  @override
  List<Object?> get props => [item];
}

final class RefreshFromSupabase extends LostFoundEvent {
  const RefreshFromSupabase();
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class LostFoundState extends Equatable {
  const LostFoundState();
  @override
  List<Object?> get props => [];
}

final class LostFoundInitial extends LostFoundState {
  const LostFoundInitial();
}

final class LostFoundLoading extends LostFoundState {
  const LostFoundLoading();
}

final class LostFoundLoaded extends LostFoundState {
  final List<LostItemModel> items;
  const LostFoundLoaded({required this.items});
  @override
  List<Object?> get props => [items];
}

final class ItemPostedSuccess extends LostFoundState {
  const ItemPostedSuccess();
}

final class ItemClaimedSuccess extends LostFoundState {
  const ItemClaimedSuccess();
}

final class LostFoundError extends LostFoundState {
  final String message;
  const LostFoundError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class LostFoundBloc extends Bloc<LostFoundEvent, LostFoundState> {
  final PostLostItemUsecase _postLostItemUsecase;
  final ClaimItemUsecase _claimItemUsecase;
  final DatabaseService _databaseService;
  final SupabaseClientService _supabaseService;

  LostFoundBloc({
    required PostLostItemUsecase postLostItemUsecase,
    required ClaimItemUsecase claimItemUsecase,
    required DatabaseService databaseService,
    required SupabaseClientService supabaseService,
  })  : _postLostItemUsecase = postLostItemUsecase,
        _claimItemUsecase = claimItemUsecase,
        _databaseService = databaseService,
        _supabaseService = supabaseService,
        super(const LostFoundInitial()) {
    on<LoadItemsRequested>(_onLoadItems);
    on<PostItemRequested>(_onPostItem);
    on<ClaimItemRequested>(_onClaimItem);
    on<RefreshFromSupabase>(_onRefreshFromSupabase);
  }

  Future<void> _onLoadItems(
    LoadItemsRequested event,
    Emitter<LostFoundState> emit,
  ) async {
    emit(const LostFoundLoading());

    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'lost_items',
        orderBy: 'created_at DESC',
      );

      final items = results.map((m) => LostItemModel.fromMap(m)).toList();
      emit(LostFoundLoaded(items: items));
    } catch (e) {
      emit(LostFoundError(message: 'Failed to load items: $e'));
    }
  }

  Future<void> _onPostItem(
    PostItemRequested event,
    Emitter<LostFoundState> emit,
  ) async {
    emit(const LostFoundLoading());

    final result = await _postLostItemUsecase(
      title: event.title,
      description: event.description,
      imagePath: event.imagePath,
      location: event.location,
    );

    result.fold(
      (failure) => emit(LostFoundError(message: failure.message)),
      (_) {
        emit(const ItemPostedSuccess());
        add(const LoadItemsRequested());
      },
    );
  }

  Future<void> _onClaimItem(
    ClaimItemRequested event,
    Emitter<LostFoundState> emit,
  ) async {
    final result = await _claimItemUsecase(item: event.item);

    result.fold(
      (failure) => emit(LostFoundError(message: failure.message)),
      (_) {
        emit(const ItemClaimedSuccess());
        add(const LoadItemsRequested());
      },
    );
  }

  Future<void> _onRefreshFromSupabase(
    RefreshFromSupabase event,
    Emitter<LostFoundState> emit,
  ) async {
    emit(const LostFoundLoading());

    try {
      final userId = _supabaseService.currentUserId;

      // Fetch from Supabase
      final response = await _supabaseService
          .from(AppConstants.tableLostItems)
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final items = (response as List)
          .map((row) => LostItemModel.fromSupabase(
              row as Map<String, dynamic>, userId))
          .toList();

      // Cache locally
      final db = await _databaseService.database;
      await db.delete('lost_items');
      for (final item in items) {
        await db.insert('lost_items', item.toMap());
      }

      emit(LostFoundLoaded(items: items));
    } catch (e) {
      // Fallback to local cache
      add(const LoadItemsRequested());
    }
  }
}
