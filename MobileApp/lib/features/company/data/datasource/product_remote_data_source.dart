import 'dart:io';

import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';
import 'package:alrasmarket/features/company/data/models/create_product_response.dart';
import 'package:alrasmarket/features/company/data/models/my_listings_response.dart';
import 'package:alrasmarket/features/company/data/models/update_listing_status_request.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class BaseProductRemoteDataSource {
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
}

class ProductRemoteDataSource implements BaseProductRemoteDataSource {
  @override
  Future<Either<Failure, CreateProductResponse>> createProduct({
    required CreateAdProductRequest request,
    required String token,
  }) async {
    try {
      final formData = await request.toFormData();
      debugPrint(
        '[CreateProduct] fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
      debugPrint(
        '[CreateProduct] files: ${formData.files.map((e) => e.key).join(', ')}',
      );
      final response = await DioHelper.uploadFile(
        url: ApiConstants.createProductEndPoint,
        formData: formData,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to create product ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid create product response'));
      }

      final productId = data['productId']?.toString() ?? '';
      if (productId.isEmpty) {
        return const Left(ServerFailure('Product id missing in response'));
      }

      return Right(CreateProductResponse.fromJson(data));
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e.response?.data) ?? e.message ?? 'Network error'));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MyListingsResponse>> getMyListings({
    required String token,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productsMyListingsEndPoint,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to load listings ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid my-listings response'));
      }

      return Right(MyListingsResponse.fromJson(data));
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct({
    required String productId,
    required String token,
  }) async {
    try {
      final response = await DioHelper.deleteData(
        url: ApiConstants.productByIdEndPoint(productId),
        token: token,
      );

      return _mapVoidResponse(
        response,
        failureFallback: 'Failed to delete product',
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Delete failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CreateProductResponse>> updateProduct({
    required String productId,
    required CreateAdProductRequest request,
    required String token,
  }) async {
    try {
      final formData = await request.toFormData(forUpdate: true);
      final response = await DioHelper.putUpload(
        url: ApiConstants.productByIdEndPoint(productId),
        formData: formData,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to update product ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return Right(CreateProductResponse.fromJson({
          ...data,
          'productId': data['productId']?.toString() ?? productId,
        }));
      }

      return Right(CreateProductResponse(productId: productId));
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Update failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductListingStatus({
    required String productId,
    required UpdateListingStatusRequest request,
    required String token,
  }) async {
    try {
      final response = await DioHelper.patchData(
        url: ApiConstants.productListingStatusEndPoint(productId),
        data: request.toJson(),
        token: token,
      );

      return _mapVoidResponse(
        response,
        failureFallback: 'Failed to update listing status',
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ??
              e.message ??
              'Listing status update failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markProductSoldOut({
    required String productId,
    required String token,
  }) async {
    try {
      final response = await DioHelper.patchData(
        url: ApiConstants.productSoldOutEndPoint(productId),
        data: const <String, dynamic>{},
        token: token,
      );

      return _mapVoidResponse(
        response,
        failureFallback: 'Failed to mark sold out',
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ??
              e.message ??
              'Mark sold out failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitProductForAdminReview({
    required String productId,
    required String token,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.productSubmitForReviewEndPoint(productId),
        data: const <String, dynamic>{},
        token: token,
      );

      return _mapVoidResponse(
        response,
        failureFallback: 'Failed to submit product for review',
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ??
              e.message ??
              'Submit for review failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProductImage({
    required String productId,
    required String filePath,
    required String token,
  }) async {
    return _uploadAsset(
      endPoint: ApiConstants.productImageUploadEndPoint(productId),
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, void>> deleteProductImageByPath({
    required String productId,
    required String imagePath,
    required String token,
  }) async {
    try {
      final normalizedPath = _normalizeRemoteImagePath(imagePath);
      if (normalizedPath.isEmpty) {
        return const Right(null);
      }
      final response = await DioHelper.deleteData(
        url: ApiConstants.productImageDeleteByPathEndPoint(productId),
        query: {'path': normalizedPath},
        token: token,
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to delete image ($status)',
          ),
        );
      }
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Delete failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProductDocument({
    required String productId,
    required String filePath,
    required String token,
  }) async {
    return _uploadAsset(
      endPoint: ApiConstants.productDocumentUploadEndPoint(productId),
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
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(
          ServerFailure(
            'File not found at upload time: $filePath. '
            'Please re-select the video and try again.',
          ),
        );
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'VideoDurationSeconds': videoDurationSeconds.toString(),
      });

      final response = await DioHelper.uploadFile(
        url: ApiConstants.productVideoUploadEndPoint(productId),
        formData: formData,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Upload failed ($status)',
          ),
        );
      }

      final path = _extractUploadedPath(response?.data);
      if (path == null || path.isEmpty) {
        return const Left(ServerFailure('Invalid upload response'));
      }

      return Right(path);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Upload failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> _uploadAsset({
    required String endPoint,
    required String filePath,
    required String token,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(
          ServerFailure(
            'File not found at upload time: $filePath. '
            'Please re-select the image and try again.',
          ),
        );
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await DioHelper.uploadFile(
        url: endPoint,
        formData: formData,
        token: token,
      );
      print('uploadProductImage response: ${response?.data}');

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        print('uploadProductImage error: ${response?.data}');
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Upload failed ($status)',
          ),
        );
      }

      final path = _extractUploadedPath(response?.data);
      if (path == null || path.isEmpty) {
        return const Left(ServerFailure('Invalid upload response'));
      }

      return Right(path);
    } on DioException catch (e) {
      print('uploadProductImage error: ${e.response?.data}');
      return Left(ServerFailure(_extractMessage(e.response?.data) ?? e.message ?? 'Upload failed'));
    } catch (e) {
      print('uploadProductImage error: ${e.toString()}');
      return Left(NetworkFailure(e.toString()));
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString();
    }
    if (data is String) return data;
    return null;
  }

  Either<Failure, void> _mapVoidResponse(
    Response? response, {
    required String failureFallback,
  }) {
    final status = response?.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      return Left(
        ServerFailure(
          _extractMessage(response?.data) ??
              response?.statusMessage ??
              '$failureFallback ($status)',
        ),
      );
    }
    return const Right(null);
  }

  String? _extractUploadedPath(dynamic data) {
    if (data is Map) {
      return data['path']?.toString() ??
          data['Path']?.toString() ??
          data['url']?.toString() ??
          data['imageUrl']?.toString() ??
          data['imagePath']?.toString() ??
          data['documentPath']?.toString();
    }
    if (data is String) return data;
    return null;
  }

  /// Matches backend ProductAssetsAppService.NormalizeAssetPath.
  static String _normalizeRemoteImagePath(String path) {
    var value = path.trim().replaceAll('\\', '/');
    if (value.startsWith('http://') || value.startsWith('https://')) {
      try {
        value = Uri.parse(value).path;
      } catch (_) {
        // keep trimmed value
      }
    }
    const marker = '/product-images/';
    final idx = value.toLowerCase().indexOf(marker);
    if (idx >= 0) {
      value = value.substring(idx);
    }
    if (value.isEmpty) return value;
    if (!value.startsWith('/')) {
      value = '/${value.replaceFirst(RegExp(r'^/+'), '')}';
    }
    return value;
  }
}
