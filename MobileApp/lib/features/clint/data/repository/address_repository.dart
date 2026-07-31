import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/datasource/address_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseAddressRepository {
  Future<Either<Failure, List<ClientAddressModel>>> getAddresses({
    required String token,
  });

  Future<Either<Failure, void>> createAddress({
    required CreateAddressRequest request,
    required String token,
  });

  Future<Either<Failure, void>> updateAddress({
    required String addressId,
    required CreateAddressRequest request,
    required String token,
  });

  Future<Either<Failure, void>> deleteAddress({
    required String addressId,
    required String token,
  });
}

class AddressRepository implements BaseAddressRepository {
  AddressRepository({required BaseAddressRemoteDataSource remote})
      : _remote = remote;

  final BaseAddressRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ClientAddressModel>>> getAddresses({
    required String token,
  }) async {
    final result = await _remote.fetchAddresses(token: token);
    return result.fold(Left.new, (response) => Right(response.items));
  }

  @override
  Future<Either<Failure, void>> createAddress({
    required CreateAddressRequest request,
    required String token,
  }) {
    return _remote.createAddress(request: request, token: token);
  }

  @override
  Future<Either<Failure, void>> updateAddress({
    required String addressId,
    required CreateAddressRequest request,
    required String token,
  }) {
    return _remote.updateAddress(
      addressId: addressId,
      request: request,
      token: token,
    );
  }

  @override
  Future<Either<Failure, void>> deleteAddress({
    required String addressId,
    required String token,
  }) {
    return _remote.deleteAddress(addressId: addressId, token: token);
  }
}
