import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

class ProductViewService {
  ProductViewService._();

  static final Set<String> _trackedProductIds = {};

  /// Calls `POST /api/Products/{id}/increase-view` once per app session per product.
  /// Skips the owner's own ads so seller previews do not inflate the counter.
  static Future<int?> trackProductView(
    String productId, {
    MyListingProductModel? product,
  }) async {
    final normalizedId = productId.trim();
    if (normalizedId.isEmpty || _trackedProductIds.contains(normalizedId)) {
      return null;
    }

    if (product != null &&
        ProductOwnershipHelper.isOwnedByCurrentUser(product)) {
      return null;
    }

    _trackedProductIds.add(normalizedId);

    try {
      final response = await DioHelper.postData(
        url: ApiConstants.productIncreaseViewEndPoint(normalizedId),
        data: const {},
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        _trackedProductIds.remove(normalizedId);
        return null;
      }

      final data = response?.data;
      if (data is Map) {
        final raw = data['viewsCount'] ?? data['ViewsCount'];
        final parsed = int.tryParse(raw?.toString() ?? '');
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // Allow a later retry if the network call failed.
      _trackedProductIds.remove(normalizedId);
    }

    return null;
  }
}
