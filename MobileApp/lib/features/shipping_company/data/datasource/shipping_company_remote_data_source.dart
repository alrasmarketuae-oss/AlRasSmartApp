import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

abstract class BaseShippingCompanyRemoteDataSource {
  Future<Either<Failure, ShippingCompanyDashboardModel>> getDashboard();
  Future<Either<Failure, List<ShippingCompanyPostModel>>> getMyPosts();
  Future<Either<Failure, ShippingCompanyPostModel>> createPost(
    Map<String, dynamic> payload,
  );
  Future<Either<Failure, ShippingCompanyPostModel>> updatePost(
    int postId,
    Map<String, dynamic> payload,
  );
  Future<Either<Failure, String>> deletePost(int postId);
  Future<Either<Failure, Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> payload,
  );
}

class ShippingCompanyRemoteDataSource
    implements BaseShippingCompanyRemoteDataSource {
  @override
  Future<Either<Failure, ShippingCompanyDashboardModel>> getDashboard() async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.shippingCompanyDashboardEndPoint,
      );
      if (response?.statusCode == 200 && response?.data is Map) {
        return Right(
          ShippingCompanyDashboardModel.fromJson(
            Map<String, dynamic>.from(response!.data as Map),
          ),
        );
      }
      return Left(ServerFailure(response?.statusMessage ?? 'Failed to load dashboard'));
    } on DioException catch (e) {
      return Left(ServerFailure(_dioMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShippingCompanyPostModel>>> getMyPosts() async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.shippingCompanyPostsEndPoint,
      );
      if (response?.statusCode == 200 && response?.data is List) {
        final items = (response!.data as List)
            .whereType<Map>()
            .map(
              (e) => ShippingCompanyPostModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
        return Right(items);
      }
      return Left(ServerFailure(response?.statusMessage ?? 'Failed to load posts'));
    } on DioException catch (e) {
      return Left(ServerFailure(_dioMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShippingCompanyPostModel>> createPost(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.shippingCompanyPostsEndPoint,
        data: payload,
      );
      if (response?.statusCode == 200 && response?.data is Map) {
        return Right(
          ShippingCompanyPostModel.fromJson(
            Map<String, dynamic>.from(response!.data as Map),
          ),
        );
      }
      return Left(ServerFailure(response?.statusMessage ?? 'Failed to create post'));
    } on DioException catch (e) {
      return Left(ServerFailure(_dioMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShippingCompanyPostModel>> updatePost(
    int postId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await DioHelper.putData(
        url: ApiConstants.shippingCompanyPostByIdEndPoint(postId),
        data: payload,
      );
      if (response?.statusCode == 200 && response?.data is Map) {
        return Right(
          ShippingCompanyPostModel.fromJson(
            Map<String, dynamic>.from(response!.data as Map),
          ),
        );
      }
      return Left(ServerFailure(response?.statusMessage ?? 'Failed to update post'));
    } on DioException catch (e) {
      return Left(ServerFailure(_dioMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deletePost(int postId) async {
    try {
      final response = await DioHelper.deleteData(
        url: ApiConstants.shippingCompanyPostByIdEndPoint(postId),
      );
      if (response?.statusCode == 200) {
        return const Right('deleted');
      }
      return Left(ServerFailure(response?.statusMessage ?? 'Failed to delete post'));
    } on DioException catch (e) {
      return Left(ServerFailure(_dioMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await DioHelper.putData(
        url: ApiConstants.userProfileEndPoint,
        data: payload,
      );
      if (response?.statusCode == 200 && response?.data is Map) {
        return Right(Map<String, dynamic>.from(response!.data as Map));
      }
      return Left(ServerFailure(response?.statusMessage ?? 'Failed to update profile'));
    } on DioException catch (e) {
      return Left(ServerFailure(_dioMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Network error';
  }
}
