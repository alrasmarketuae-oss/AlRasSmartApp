import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ProductShareHelper {
  ProductShareHelper._();

  static Future<void> shareProduct(
    BuildContext context,
    MyListingProductModel product,
  ) async {
    final s = S.of(context);
    final name = product.productName.capitalizeFirst();
    final displayName = name.isEmpty ? s.product : name;
    final code = product.productCode.trim();
    final lines = <String>[displayName];

    if (code.isNotEmpty) {
      lines.add('${s.productCode}: $code');
      lines.add(s.shareProductSearchHint);
    } else {
      lines.add(s.shareProductHint);
    }

    // iOS/iPad require a non-zero sharePositionOrigin or the sheet can fail silently.
    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    origin ??= _fallbackShareOrigin(context);

    try {
      await Share.share(
        lines.join('\n'),
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('Product share failed: $e');
      if (context.mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        AppToast.showError(
          context,
          isAr ? 'تعذر مشاركة المنتج' : 'Could not share product',
        );
      }
    }
  }

  static Rect _fallbackShareOrigin(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Anchor near the top-trailing action area (share icon).
    final width = 48.0;
    final height = 48.0;
    final left = size.width - width - 16;
    final top = MediaQuery.paddingOf(context).top + 8;
    return Rect.fromLTWH(left, top, width, height);
  }
}
