import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';

/// Holds a structured address collected during register until the user has a JWT.
class PendingRegistrationAddress {
  static CreateAddressRequest? _pending;

  static void store(CreateAddressRequest request) {
    _pending = request;
  }

  static CreateAddressRequest? take() {
    final value = _pending;
    _pending = null;
    return value;
  }
}
