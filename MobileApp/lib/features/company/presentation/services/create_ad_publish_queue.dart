import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/media/media_compression_service.dart';
import 'package:alrasmarket/core/media/video_compressor.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/company/data/datasource/product_remote_data_source.dart';
import 'package:alrasmarket/features/company/data/repository/product_repository.dart';
import 'package:alrasmarket/features/company/domain/repository/base_product_repository.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_job.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_store.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Disk-backed sequential queue for create-ad media compress + upload.
///
/// Product create happens on the UI first. This queue attaches media afterward
/// on the main isolate (no Android Foreground Service).
class CreateAdPublishQueue {
  CreateAdPublishQueue._();

  static final CreateAdPublishQueue instance = CreateAdPublishQueue._();

  bool _processing = false;

  /// Persist job then start media work without blocking the Publish button.
  Future<void> enqueue(CreateAdPublishJob job) async {
    await CreateAdPublishStore.instance.enqueue(job);
    debugPrint(
      '[CreateAdPublishQueue] enqueued ${job.id} '
      '(productId=${job.createdProductId}, '
      'images=${job.imagePaths.length}, video=${job.rawVideoPath != null})',
    );

    // Do not await — UI navigates away while upload continues in-app.
    unawaited(drainFromDisk());
  }

  Future<void> restoreAndResume() async {
    final pending = await CreateAdPublishStore.instance.count();
    if (pending == 0) return;
    debugPrint('[CreateAdPublishQueue] restoring $pending job(s)');
    unawaited(drainFromDisk());
  }

  Future<void> drainFromDisk({
    Future<void> Function(int remaining)? onProgress,
  }) async {
    if (_processing) return;
    if (!await CreateAdPublishStore.instance.tryAcquireProcessingLock()) {
      debugPrint('[CreateAdPublishQueue] another isolate is draining');
      return;
    }
    _processing = true;
    try {
      while (true) {
        final remainingBefore = await CreateAdPublishStore.instance.count();
        if (remainingBefore == 0) break;
        await CreateAdPublishStore.instance.heartbeatProcessingLock();
        await onProgress?.call(remainingBefore);

        final job = await CreateAdPublishStore.instance.peekFirst();
        if (job == null) break;

        final shouldRemove = await _process(job);
        if (shouldRemove) {
          await CreateAdPublishStore.instance.removeById(job.id);
        } else {
          break;
        }
      }
    } catch (e, st) {
      debugPrint('[CreateAdPublishQueue] drain crashed: $e\n$st');
      _reportError(S.current.adBackgroundUploadFailedGeneric);
    } finally {
      _processing = false;
      await CreateAdPublishStore.instance.releaseProcessingLock();
    }
  }

  Future<void> _notify(String text) async {
    debugPrint('[CreateAdPublishQueue] $text');
  }

  void _ensureUploadDependencies() {
    if (!sl.isRegistered<BaseProductRemoteDataSource>()) {
      sl.registerLazySingleton<BaseProductRemoteDataSource>(
        () => ProductRemoteDataSource(),
      );
    }
    if (!sl.isRegistered<BaseProductRepository>()) {
      sl.registerLazySingleton<BaseProductRepository>(
        () => ProductRepository(remote: sl()),
      );
    }
    if (!sl.isRegistered<CreateProductUseCase>()) {
      sl.registerLazySingleton(() => CreateProductUseCase(sl()));
    }
    if (!sl.isRegistered<UpdateProductUseCase>()) {
      sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
    }
    if (!sl.isRegistered<UploadProductImagesUseCase>()) {
      sl.registerLazySingleton(() => UploadProductImagesUseCase(sl()));
    }
    if (!sl.isRegistered<UploadProductDocumentsUseCase>()) {
      sl.registerLazySingleton(() => UploadProductDocumentsUseCase(sl()));
    }
    if (!sl.isRegistered<UploadProductVideoUseCase>()) {
      sl.registerLazySingleton(() => UploadProductVideoUseCase(sl()));
    }
    if (!sl.isRegistered<SubmitProductForAdminReviewUseCase>()) {
      sl.registerLazySingleton(() => SubmitProductForAdminReviewUseCase(sl()));
    }
  }

  Future<bool> _process(CreateAdPublishJob job) async {
    debugPrint('[CreateAdPublishQueue] processing ${job.id}');
    Future<void> beat() =>
        CreateAdPublishStore.instance.heartbeatProcessingLock();

    try {
      _ensureUploadDependencies();
      var working = job;

      var productId = working.createdProductId;
      if (productId == null || productId.isEmpty) {
        if (!sl.isRegistered<CreateProductUseCase>()) {
          _reportError(S.current.adBackgroundUploadFailedGeneric);
          return false;
        }
        await beat();
        debugPrint('[CreateAdPublishQueue] creating product on API…');
        final createProduct = sl<CreateProductUseCase>();
        final createResult = await createProduct(
          request: working.request.copyWith(clearProductVideoFile: true),
          token: working.token,
        );

        productId = createResult.fold<String?>((failure) {
          _reportError(failure.message);
          return null;
        }, (response) => response.productId);

        if (productId == null || productId.isEmpty) return true;

        working = working.copyWith(createdProductId: productId);
        await CreateAdPublishStore.instance.update(working);
        debugPrint('[CreateAdPublishQueue] created product $productId');
      }

      final compressedImages = <String>[];
      if (working.imagePaths.isNotEmpty) {
        await _notify(S.current.adUploadProgressCompressingImages);
        final existing = <String>[];
        for (final path in working.imagePaths) {
          await beat();
          if (!await File(path).exists()) {
            debugPrint('[CreateAdPublishQueue] missing image: $path');
            continue;
          }
          existing.add(path);
        }
        if (existing.isNotEmpty) {
          final prepared =
              await MediaCompressionService.prepareAdMediaMany(existing);
          compressedImages.addAll(prepared);
        }
      }

      if (compressedImages.isNotEmpty) {
        if (!sl.isRegistered<UploadProductImagesUseCase>()) {
          _reportError(S.current.adBackgroundUploadFailedGeneric);
          return false;
        }
        await beat();
        await _notify(S.current.adUploadProgressUploadingImages);
        debugPrint(
          '[CreateAdPublishQueue] uploading ${compressedImages.length} image(s)…',
        );
        final uploadImages = sl<UploadProductImagesUseCase>();
        final imagesResult = await uploadImages(
          productId: productId,
          filePaths: compressedImages,
          token: working.token,
        );
        final imagesError = imagesResult.fold<String?>(
          (failure) => failure.message,
          (_) => null,
        );
        if (imagesError != null) {
          _reportError(imagesError);
          return false;
        }
        working = working.copyWith(imagePaths: const []);
        await CreateAdPublishStore.instance.update(working);
      }

      if (!working.skipDocuments && working.documentPaths.isNotEmpty) {
        if (!sl.isRegistered<UploadProductDocumentsUseCase>()) {
          _reportError(S.current.adBackgroundUploadFailedGeneric);
          return false;
        }
        await beat();
        await _notify(S.current.adUploadProgressAttachingMedia);
        final uploadDocs = sl<UploadProductDocumentsUseCase>();
        final docsResult = await uploadDocs(
          productId: productId,
          filePaths: working.documentPaths,
          token: working.token,
        );
        final docsError = docsResult.fold<String?>(
          (failure) => failure.message,
          (_) => null,
        );
        if (docsError != null) {
          _reportError(docsError);
          return false;
        }
      }

      final sourceVideo = working.rawVideoPath;
      if (sourceVideo != null && sourceVideo.isNotEmpty) {
        if (!await File(sourceVideo).exists() &&
            (working.compressedVideoPath == null ||
                working.compressedVideoPath!.isEmpty ||
                !await File(working.compressedVideoPath!).exists())) {
          debugPrint('[CreateAdPublishQueue] missing video file');
          _reportError(S.current.videoFileNotFound);
          return true;
        }

        var videoPath = working.compressedVideoPath;
        if (videoPath == null ||
            videoPath.isEmpty ||
            !await File(videoPath).exists()) {
          await beat();
          debugPrint('[CreateAdPublishQueue] compressing video…');
          await _notify(S.current.adUploadProgressCompressingVideo(0));
          final compressedVideo = await MediaCompressionService.prepareAdMedia(
            sourceVideo,
            onProgress: (p) {
              unawaited(
                _notify(
                  S.current.adUploadProgressCompressingVideo(
                    (p * 100).round().clamp(0, 99),
                  ),
                ),
              );
            },
          );
          if (compressedVideo == null) {
            _reportError(
              S.current.videoCompressFailed(
                CreateAdFormMapper.maxProductVideoSizeMb,
              ),
            );
            return false;
          }
          videoPath = compressedVideo;
          working = working.copyWith(compressedVideoPath: videoPath);
          await CreateAdPublishStore.instance.update(working);
          await beat();
        }

        final sizeError = await CreateAdFormMapper.validateVideoFile(videoPath);
        if (sizeError != null) {
          _reportError(sizeError);
          return false;
        }

        final durationError = await CreateAdFormMapper.validateVideoDuration(
          videoPath,
          tooLongMessage: S.current.videoMaxDurationSeconds,
          unreadableMessage: S.current.videoDurationUnreadable,
        );
        if (durationError != null) {
          _reportError(durationError);
          return false;
        }

        final durationSeconds =
            await VideoCompressor.readDurationSecondsRounded(
          videoPath,
          maxSeconds: CreateAdFormMapper.maxProductVideoDurationSeconds,
        );
        if (durationSeconds < 1) {
          _reportError(S.current.videoDurationUnreadable);
          return false;
        }

        if (!sl.isRegistered<UploadProductVideoUseCase>()) {
          _reportError(S.current.adBackgroundUploadFailedGeneric);
          return false;
        }
        await beat();
        await _notify(S.current.adUploadProgressUploadingVideo);
        debugPrint('[CreateAdPublishQueue] attaching video via upload…');
        final uploadVideo = sl<UploadProductVideoUseCase>();
        final uploadResult = await uploadVideo(
          productId: productId,
          filePath: videoPath,
          videoDurationSeconds: durationSeconds,
          token: working.token,
        );
        final updateError = uploadResult.fold<String?>(
          (failure) => failure.message,
          (_) => null,
        );
        if (updateError != null) {
          _reportError(updateError);
          return false;
        }
      }

      if (!sl.isRegistered<SubmitProductForAdminReviewUseCase>()) {
        _reportError(S.current.adBackgroundUploadFailedGeneric);
        return false;
      }
      await beat();
      await _notify(S.current.adUploadProgressDone);
      debugPrint('[CreateAdPublishQueue] submit-for-review $productId…');
      final submitForReview = sl<SubmitProductForAdminReviewUseCase>();
      final submitResult = await submitForReview(
        productId: productId,
        token: working.token,
      );
      final submitError = submitResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (submitError != null) {
        _reportError(submitError);
        return false;
      }

      await _notify(S.current.adUploadProgressDone);

      try {
        unawaited(CatalogSyncService.instance.afterAdMutation());
      } catch (e) {
        debugPrint('[CreateAdPublishQueue] catalog sync skipped: $e');
      }
      debugPrint('[CreateAdPublishQueue] completed ${working.id} → $productId');
      return true;
    } catch (e, st) {
      debugPrint('[CreateAdPublishQueue] failed ${job.id}: $e\n$st');
      final name = job.productName.trim();
      _reportError(
        name.isEmpty
            ? S.current.adBackgroundUploadFailedGeneric
            : S.current.adBackgroundUploadFailed(name),
      );
      return false;
    }
  }

  void _reportError(String message) {
    showUiError(message);
  }

  void showUiError(String message) {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    AppToast.showError(context, message);
  }
}
