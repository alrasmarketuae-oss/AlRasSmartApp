import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

/// True when the signed-in user owns this listing (cannot buy/offer on it).
class ProductOwnershipHelper {
  ProductOwnershipHelper._();

  static bool isOwnedByCurrentUser(MyListingProductModel product) {
    final me = AuthService.instance.currentUserID?.trim().toLowerCase() ?? '';
    final owner = product.ownerId.trim().toLowerCase();
    return me.isNotEmpty && owner.isNotEmpty && me == owner;
  }

  static bool isOwnedByCurrentUserId(String? ownerId) {
    final me = AuthService.instance.currentUserID?.trim().toLowerCase() ?? '';
    final owner = ownerId?.trim().toLowerCase() ?? '';
    return me.isNotEmpty && owner.isNotEmpty && me == owner;
  }
}
