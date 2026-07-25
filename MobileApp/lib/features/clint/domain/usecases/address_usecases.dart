import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/data/repository/address_repository.dart';
import 'package:dartz/dartz.dart';

class GetClientAddressesUseCase {
  GetClientAddressesUseCase(this._repository);

  final BaseAddressRepository _repository;

  Future<Either<Failure, List<ClientAddressModel>>> call({
    required String token,
  }) {
    return _repository.getAddresses(token: token);
  }
}

class CreateClientAddressUseCase {
  CreateClientAddressUseCase(this._repository);

  final BaseAddressRepository _repository;

  Future<Either<Failure, void>> call({
    required CreateAddressRequest request,
    required String token,
  }) {
    return _repository.createAddress(request: request, token: token);
  }
}
