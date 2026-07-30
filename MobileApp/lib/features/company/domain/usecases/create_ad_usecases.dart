import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';
import 'package:alrasmarket/features/company/data/models/create_product_response.dart';
import 'package:alrasmarket/features/company/data/models/my_listings_response.dart';
import 'package:alrasmarket/features/company/data/models/update_listing_status_request.dart';
import 'package:alrasmarket/features/company/domain/repository/base_product_repository.dart';
import 'package:dartz/dartz.dart';

class CreateProductUseCase {
  CreateProductUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, CreateProductResponse>> call({
    required CreateAdProductRequest request,
    required String token,
  }) {
    return _repository.createProduct(request: request, token: token);
  }
}

class GetMyListingsUseCase {
  GetMyListingsUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, MyListingsResponse>> call({required String token}) {
    return _repository.getMyListings(token: token);
  }
}

class DeleteProductUseCase {
  DeleteProductUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, void>> call({
    required String productId,
    required String token,
  }) {
    return _repository.deleteProduct(productId: productId, token: token);
  }
}

class UpdateProductUseCase {
  UpdateProductUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, CreateProductResponse>> call({
    required String productId,
    required CreateAdProductRequest request,
    required String token,
  }) {
    return _repository.updateProduct(
      productId: productId,
      request: request,
      token: token,
    );
  }
}

class UpdateProductListingStatusUseCase {
  UpdateProductListingStatusUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, void>> call({
    required String productId,
    required bool isActive,
    required String token,
  }) {
    return _repository.updateProductListingStatus(
      productId: productId,
      request: UpdateListingStatusRequest(isActive: isActive),
      token: token,
    );
  }
}

class MarkProductSoldOutUseCase {
  MarkProductSoldOutUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, void>> call({
    required String productId,
    required String token,
  }) {
    return _repository.markProductSoldOut(
      productId: productId,
      token: token,
    );
  }
}

class UploadProductImagesUseCase {
  UploadProductImagesUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, List<String>>> call({
    required String productId,
    required List<String> filePaths,
    required String token,
  }) async {
    final uploadedPaths = <String>[];
    for (final filePath in filePaths) {
      final uploadEither = await _repository.uploadProductImage(
        productId: productId,
        filePath: filePath,
        token: token,
      );
      final stopFailure = uploadEither.fold<Failure?>(
        (failure) => failure,
        (path) {
          uploadedPaths.add(path);
          return null;
        },
      );
      if (stopFailure != null) return Left(stopFailure);
    }
    return Right(uploadedPaths);
  }
}

class DeleteProductImagesByPathUseCase {
  DeleteProductImagesByPathUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, void>> call({
    required String productId,
    required List<String> imagePaths,
    required String token,
  }) async {
    for (final path in imagePaths) {
      if (path.trim().isEmpty) continue;

      final result = await _repository.deleteProductImageByPath(
        productId: productId,
        imagePath: path,
        token: token,
      );
      final error = result.fold<Failure?>((f) => f, (_) => null);
      if (error == null) continue;

      // Already removed on server — do not block the rest of the edit.
      final message = error.message.toLowerCase();
      if (message.contains('not found') ||
          message.contains('404') ||
          message.contains('image path is required')) {
        continue;
      }
      return Left(error);
    }
    return const Right(null);
  }
}

class UploadProductDocumentsUseCase {
  UploadProductDocumentsUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, List<String>>> call({
    required String productId,
    required List<String> filePaths,
    required String token,
  }) async {
    final uploadedPaths = <String>[];
    for (final filePath in filePaths) {
      final uploadEither = await _repository.uploadProductDocument(
        productId: productId,
        filePath: filePath,
        token: token,
      );
      final stopFailure = uploadEither.fold<Failure?>(
        (failure) => failure,
        (path) {
          uploadedPaths.add(path);
          return null;
        },
      );
      if (stopFailure != null) return Left(stopFailure);
    }
    return Right(uploadedPaths);
  }
}

class UploadProductVideoUseCase {
  UploadProductVideoUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, String>> call({
    required String productId,
    required String filePath,
    required int videoDurationSeconds,
    required String token,
  }) {
    return _repository.uploadProductVideo(
      productId: productId,
      filePath: filePath,
      videoDurationSeconds: videoDurationSeconds,
      token: token,
    );
  }
}

/// After media uploads — notifies admin dashboard that the ad is ready to review.
class SubmitProductForAdminReviewUseCase {
  SubmitProductForAdminReviewUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, void>> call({
    required String productId,
    required String token,
  }) {
    return _repository.submitProductForAdminReview(
      productId: productId,
      token: token,
    );
  }
}

/// Bundles all draft (pre-product) R2 upload operations into a single injectable.
///
/// Draft images/videos are uploaded immediately after the user picks media —
/// before the product record is created — so bytes are already in R2 by the
/// time the user taps Publish. On publish, confirm endpoints attach the already-
/// uploaded objects to the new product. Abandoned drafts are deleted on remove
/// or cubit close.
class ProductDraftOpsUseCase {
  ProductDraftOpsUseCase(this._repository);

  final BaseProductRepository _repository;

  Future<Either<Failure, String>> uploadDraftImage({
    required String filePath,
    required String token,
  }) {
    return _repository.draftPresignAndPutImage(filePath: filePath, token: token);
  }

  Future<Either<Failure, String>> uploadDraftVideo({
    required String filePath,
    required String token,
  }) {
    return _repository.draftPresignAndPutVideo(filePath: filePath, token: token);
  }

  /// Fire-and-forget — always returns void, never throws.
  Future<void> deleteDraft({
    required String draftPath,
    required String token,
  }) async {
    await _repository.deleteDraft(draftPath: draftPath, token: token);
  }

  Future<Either<Failure, void>> confirmDraftImage({
    required String productId,
    required String draftPath,
    required String token,
  }) {
    return _repository.confirmDraftImage(
      productId: productId,
      draftPath: draftPath,
      token: token,
    );
  }

  Future<Either<Failure, void>> confirmDraftAssetsBatch({
    required String productId,
    required List<String> imagePaths,
    String? videoPath,
    int? videoDurationSeconds,
    required String token,
  }) {
    return _repository.confirmDraftAssetsBatch(
      productId: productId,
      imagePaths: imagePaths,
      videoPath: videoPath,
      videoDurationSeconds: videoDurationSeconds,
      token: token,
    );
  }

  Future<Either<Failure, void>> confirmDraftVideo({
    required String productId,
    required String draftPath,
    required int videoDurationSeconds,
    required String token,
  }) {
    return _repository.confirmDraftVideo(
      productId: productId,
      draftPath: draftPath,
      videoDurationSeconds: videoDurationSeconds,
      token: token,
    );
  }
}
