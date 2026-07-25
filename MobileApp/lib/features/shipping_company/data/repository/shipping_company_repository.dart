import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/shipping_company/data/datasource/shipping_company_remote_data_source.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';
import 'package:dartz/dartz.dart';

class ShippingCompanyRepository {
  ShippingCompanyRepository({required this.remote});

  final BaseShippingCompanyRemoteDataSource remote;

  Future<Either<Failure, ShippingCompanyDashboardModel>> getDashboard() =>
      remote.getDashboard();

  Future<Either<Failure, List<ShippingCompanyPostModel>>> getMyPosts() =>
      remote.getMyPosts();

  Future<Either<Failure, ShippingCompanyPostModel>> createPost(
    Map<String, dynamic> payload,
  ) =>
      remote.createPost(payload);

  Future<Either<Failure, ShippingCompanyPostModel>> updatePost(
    int postId,
    Map<String, dynamic> payload,
  ) =>
      remote.updatePost(postId, payload);

  Future<Either<Failure, String>> deletePost(int postId) =>
      remote.deletePost(postId);

  Future<Either<Failure, Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> payload,
  ) =>
      remote.updateProfile(payload);
}
