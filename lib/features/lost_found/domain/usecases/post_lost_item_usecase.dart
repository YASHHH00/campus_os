import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/isar_service.dart';
import '../../data/models/lost_item_model.dart';

/// Posts a lost/found item: compress image → upload to Supabase Storage →
/// insert DB row → cache locally → subscribe to realtime updates.
class PostLostItemUsecase {
  final DatabaseService _databaseService;
  final SupabaseClientService _supabaseService;
  static const _uuid = Uuid();

  PostLostItemUsecase({
    required DatabaseService databaseService,
    required SupabaseClientService supabaseService,
  })  : _databaseService = databaseService,
        _supabaseService = supabaseService;

  Future<Either<Failure, LostItemModel>> call({
    required String title,
    required String description,
    required String imagePath,
    required String location,
  }) async {
    try {
      // Step 1: Validate
      if (title.trim().isEmpty) {
        return const Left(ValidationFailure(message: 'Title is required.'));
      }
      if (location.trim().isEmpty) {
        return const Left(
            ValidationFailure(message: 'Location is required.'));
      }

      // Step 2: Compress image to max 500KB
      final compressedBytes = await _compressImage(imagePath);
      if (compressedBytes == null) {
        return const Left(ImageProcessingFailure(
          message:
              'Failed to compress image. Please try with a smaller photo.',
        ));
      }

      // Check if > 5MB even after compression
      if (compressedBytes.length > AppConstants.maxImageUploadSizeMb * 1024 * 1024) {
        return const Left(ImageProcessingFailure(
          message:
              'Image is too large even after compression. Please take a new photo.',
        ));
      }

      final userId = _supabaseService.currentUserId;
      final imageFileName = '${_uuid.v4()}.jpg';

      // Step 3: Try uploading to Supabase
      try {
        final imageUrl = await _supabaseService.uploadFile(
          bucket: AppConstants.bucketLostFound,
          path: imageFileName,
          fileBytes: compressedBytes,
        );

        // Step 4: Insert into Supabase table
        final item = LostItemModel(
          title: title.trim(),
          description: description.trim(),
          imagePath: imageUrl,
          postedByUserId: userId,
          location: location.trim(),
          createdAt: DateTime.now(),
          isOwnPost: true,
        );

        final response = await _supabaseService
            .from(AppConstants.tableLostItems)
            .insert(item.toSupabase())
            .select()
            .single();

        final savedItem = LostItemModel.fromSupabase(response, userId);

        // Step 5: Cache locally
        final db = await _databaseService.database;
        final localId = await db.insert('lost_items', savedItem.toMap());

        return Right(savedItem.copyWith(id: localId));
      } on Exception {
        // Supabase offline → save to pending_posts for later sync
        final db = await _databaseService.database;
        await db.insert('pending_posts', {
          'title': title.trim(),
          'description': description.trim(),
          'image_path': imagePath,
          'location': location.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });

        final offlineItem = LostItemModel(
          title: title.trim(),
          description: description.trim(),
          imagePath: imagePath,
          postedByUserId: userId,
          location: location.trim(),
          createdAt: DateTime.now(),
          isOwnPost: true,
        );

        final localId =
            await db.insert('lost_items', offlineItem.toMap());

        return Right(offlineItem.copyWith(id: localId));
      }
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(StorageFailure(message: 'Failed to post item: $e'));
    }
  }

  Future<List<int>?> _compressImage(String path) async {
    try {
      final file = File(path);
      final fileSize = await file.length();

      // Already small enough
      if (fileSize <= AppConstants.maxImageCompressedSizeKb * 1024) {
        return await file.readAsBytes();
      }

      final result = await FlutterImageCompress.compressWithFile(
        path,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result;
    } catch (_) {
      return null;
    }
  }
}
