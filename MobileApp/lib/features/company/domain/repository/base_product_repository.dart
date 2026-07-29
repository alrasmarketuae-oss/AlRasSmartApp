import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';
import 'package:alrasmarket/features/company/data/models/create_product_response.dart';
import 'package:alrasmarket/features/company/data/models/my_listings_response.dart';
import 'package:alrasmarket/features/company/data/models/update_listing_status_request.dart';
import 'package:dartz/dartz.dart';

abstract class BaseProductRepository {
  Future<Either<Failure, CreateProductResponse>> createProduct({
    required CreateAdProductRequest request,
    required String token,
  });

  Future<Either<Failure, MyListingsResponse>> getMyListings({
    required String token,
  });

  Future<Either<Failure, void>> deleteProduct({
    required String productId,
    required String token,
  });

  Future<Either<Failure, CreateProductResponse>> updateProduct({
    required String productId,
    required CreateAdProductRequest request,
    required String token,
  });

  Future<Either<Failure, void>> updateProductListingStatus({
    required String productId,
    required UpdateListingStatusRequest request,
    required String token,
  });

  Future<Either<Failure, void>> markProductSoldOut({
    required String productId,
    required String token,
  });

  /// After images/videos finish uploading — shows the ad on the admin dashboard.
  Future<Either<Failure, void>> submitProductForAdminReview({
    required String productId,
    required String token,
  });

  Future<Either<Failure, String>> uploadProductImage({
    required String productId,
    required String filePath,
    required String token,
  });

  Future<Either<Failure, void>> deleteProductImageByPath({
    required String productId,
    required String imagePath,
    required String token,
  });

  Future<Either<Failure, String>> uploadProductDocument({
    required String productId,
    required String filePath,
    required String token,
  });

  Future<Either<Failure, String>> uploadProductVideo({
    required String productId,
    required String filePath,
    required int videoDurationSeconds,
    required String token,
  });

  Future<Either<Failure, String>> draftPresignAndPutImage({
    required String filePath,
    required String token,
  });

  Future<Either<Failure, String>> draftPresignAndPutVideo({
    required String filePath,
    required String token,
  });

  Future<Either<Failure, void>> deleteDraft({
    required String draftPath,
    required String token,
  });

  Future<Either<Failure, void>> confirmDraftImage({
    required String productId,
    required String draftPath,
    required String token,
  });

  Future<Either<Failure, void>> confirmDraftVideo({
    required String productId,
    required String draftPath,
    required int videoDurationSeconds,
    required String token,
  });
}
