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

    await Share.share(lines.join('\n'));
  }
}
