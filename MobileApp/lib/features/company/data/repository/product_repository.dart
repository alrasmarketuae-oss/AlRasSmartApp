import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/company/data/datasource/product_remote_data_source.dart';
import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';
import 'package:alrasmarket/features/company/data/models/create_product_response.dart';
import 'package:alrasmarket/features/company/data/models/my_listings_response.dart';
import 'package:alrasmarket/features/company/data/models/update_listing_status_request.dart';
import 'package:alrasmarket/features/company/domain/repository/base_product_repository.dart';
import 'package:dartz/dartz.dart';

class ProductRepository implements BaseProductRepository {
  ProductRepository({required BaseProductRemoteDataSource remote}) : _remote = remote;

  final BaseProductRemoteDataSource _remote;

  @override
  Future<Either<Failure, CreateProductResponse>> createProduct({
    required CreateAdProductRequest request,
    required String token,
  }) {
    return _remote.createProduct(request: request, token: token);
  }

  @override
  Future<Either<Failure, MyListingsResponse>> getMyListings({
    required String token,
  }) {
    return _remote.getMyListings(token: token);
  }

  @override
  Future<Either<Failure, void>> deleteProduct({
    required String productId,
    required String token,
  }) {
    return _remote.deleteProduct(productId: productId, token: token);
  }

  @override
  Future<Either<Failure, CreateProductResponse>> updateProduct({
    required String productId,
    required CreateAdProductRequest request,
    required String token,
  }) {
    return _remote.updateProduct(
      productId: productId,
      request: request,
      token: token,
    );
  }

  @override
  Future<Either<Failure, void>> updateProductListingStatus({
    required String productId,
    required UpdateListingStatusRequest request,
    required String token,
  }) {
    return _remote.updateProductListingStatus(
      productId: productId,
      request: request,
      token: token,
    );
  }

  @override
  Future<Either<Failure, void>> markProductSoldOut({
    required String productId,
    required String token,
  }) {
    return _remote.markProductSoldOut(productId: productId, token: token);
  }

  @override
  Future<Either<Failure, void>> submitProductForAdminReview({
    required String productId,
    required String token,
  }) {
    return _remote.submitProductForAdminReview(
      productId: productId,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadProductImage({
    required String productId,
    required String filePath,
    required String token,
  }) {
    return _remote.uploadProductImage(
      productId: productId,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, void>> deleteProductImageByPath({
    required String productId,
    required String imagePath,
    required String token,
  }) {
    return _remote.deleteProductImageByPath(
      productId: productId,
      imagePath: imagePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadProductDocument({
    required String productId,
    required String filePath,
    required String token,
  }) {
    return _remote.uploadProductDocument(
      productId: productId,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadProductVideo({
    required String productId,
    required String filePath,
    required int videoDurationSeconds,
    required String token,
  }) {
    return _remote.uploadProductVideo(
      productId: productId,
      filePath: filePath,
      videoDurationSeconds: videoDurationSeconds,
      token: token,
    );
  }
}
