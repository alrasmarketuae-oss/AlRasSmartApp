import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_facts_card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RetailProductSummaryWidget extends StatelessWidget {
  const RetailProductSummaryWidget({
    super.key,
    required this.product,
    required this.fontFamily,
    this.isOffer = false,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final bool isOffer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final description = BookingDetailsMapper.descriptionText(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.productName.isEmpty
              ? s.product
              : product.productName.capitalizeFirst(),
          style: TextStyle(
            color: ProductGridLayout.productCardTitleColor(context),
            fontFamily: fontFamily,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              color: const Color(0xFF333333).withValues(alpha: 0.8),
              fontFamily: fontFamily,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
        ],
        SizedBox(height: 16.h),
        ProductDetailFactsCard(
          product: product,
          fontFamily: fontFamily,
          mode: isOffer
              ? ProductDetailFactsMode.offer
              : ProductDetailFactsMode.retail,
        ),
      ],
    );
  }
}
