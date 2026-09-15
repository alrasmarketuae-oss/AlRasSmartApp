import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';

/// Holds a structured address collected during register until the user has a JWT
/// or until it is sent with register-company.
class PendingRegistrationAddress {
  static CreateAddressRequest? _pending;

  static void store(CreateAddressRequest request) {
    _pending = request;
  }

  static CreateAddressRequest? peek() => _pending;

  static CreateAddressRequest? take() {
    final value = _pending;
    _pending = null;
    return value;
  }

  static void clear() {
    _pending = null;
  }
}
