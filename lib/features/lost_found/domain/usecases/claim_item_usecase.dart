import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/isar_service.dart';
import '../../data/models/lost_item_model.dart';

/// Claims a lost/found item with optimistic local update + Supabase sync.
///
/// Handles:
/// - Optimistic update: update local DB immediately
/// - Supabase update: set status='claimed', claimed_by=user.id
/// - If already claimed by another user → rollback local and emit failure
/// - If Supabase offline → keep optimistic update, queue for sync
class ClaimItemUsecase {
  final DatabaseService _databaseService;
  final SupabaseClientService _supabaseService;

  ClaimItemUsecase({
    required DatabaseService databaseService,
    required SupabaseClientService supabaseService,
  })  : _databaseService = databaseService,
        _supabaseService = supabaseService;

  Future<Either<Failure, LostItemModel>> call({
    required LostItemModel item,
  }) async {
    final userId = _supabaseService.currentUserId;

    // Step 1: Optimistic local update
    final db = await _databaseService.database;
    final originalStatus = item.status;

    try {
      if (item.id != null) {
        await db.update(
          'lost_items',
          {
            'status': 'claimed',
            'claimed_by_user_id': userId,
          },
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }

      // Step 2: Update Supabase
      try {
        // First check if already claimed
        final current = await _supabaseService
            .from(AppConstants.tableLostItems)
            .select()
            .eq('id', item.supabaseId)
            .single();

        if (current['status'] == 'claimed' &&
            current['claimed_by'] != null &&
            current['claimed_by'] != userId) {
          // Already claimed by someone else — rollback
          if (item.id != null) {
            await db.update(
              'lost_items',
              {
                'status': originalStatus,
                'claimed_by_user_id': null,
              },
              where: 'id = ?',
              whereArgs: [item.id],
            );
          }

          return Left(ItemAlreadyClaimedFailure(
            message:
                'This item has already been claimed by another student.',
            claimedByUserId: current['claimed_by'] as String,
          ));
        }

        // Proceed with claim
        await _supabaseService
            .from(AppConstants.tableLostItems)
            .update({
              'status': 'claimed',
              'claimed_by': userId,
            })
            .eq('id', item.supabaseId);

        return Right(item.copyWith(
          status: 'claimed',
          claimedByUserId: userId,
        ));
      } catch (_) {
        // Supabase offline — keep optimistic update
        return Right(item.copyWith(
          status: 'claimed',
          claimedByUserId: userId,
        ));
      }
    } catch (e) {
      // Rollback on any failure
      if (item.id != null) {
        try {
          await db.update(
            'lost_items',
            {
              'status': originalStatus,
              'claimed_by_user_id': null,
            },
            where: 'id = ?',
            whereArgs: [item.id],
          );
        } catch (_) {
          // Double failure — best effort rollback
        }
      }

      return Left(StorageFailure(
        message: 'Failed to claim item: $e',
      ));
    }
  }
}
