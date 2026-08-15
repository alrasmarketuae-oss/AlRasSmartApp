import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/category_localization.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Compact product facts shown on listing cards (replaces the old action button).
class ProductCardDetails extends StatelessWidget {
  const ProductCardDetails({super.key, required this.product});

  final MyListingProductModel product;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lines = _detailLines(context, s);
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) SizedBox(height: 3.h),
            Text(
              lines[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: lines[i] == s.soldOut
                    ? const Color(0xFFDC2626)
                    : AppColors.subtitle(context),
                fontFamily: 'Inter',
                fontSize: 11.sp,
                fontWeight:
                    lines[i] == s.soldOut ? FontWeight.w700 : FontWeight.w400,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _detailLines(BuildContext context, S s) {
    final lines = <String>[];

    final code = product.productCode.trim();
    if (code.isNotEmpty) {
      lines.add('${s.productCode}: $code');
    }

    final category = product.categoryName.trim();
    if (category.isNotEmpty && category != '—') {
      lines.add(
        '${s.category}: ${localizedCategoryName(context, category)}',
      );
    } else {
      final type = product.productTypeName.trim();
      if (type.isNotEmpty) {
        lines.add(_localizedType(s, type));
      }
    }

    if (ProductStock.isSoldOut(product)) {
      lines.add(s.soldOut);
    } else {
      final available =
          ProductQuantityFormatter.availableQuantityLabel(product, s);
      if (available.isNotEmpty) {
        lines.add(available);
      }
    }

    if (product.isNegotiable && lines.length < 3) {
      lines.add(s.negotiable);
    }

    return lines.take(3).toList();
  }

  String _localizedType(S s, String typeName) {
    switch (typeName.trim().toLowerCase()) {
      case 'retail':
        return s.retail;
      case 'booking':
        return s.booking;
      case 'offers':
        return s.offers;
      case 'requests':
        return s.requests;
      default:
        return typeName.trim();
    }
  }
}
