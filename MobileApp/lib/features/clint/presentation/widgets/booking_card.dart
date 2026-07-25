import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_card_marketplace_layout.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_card_theme.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Legacy wide booking card — now uses the unified marketplace card design.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.product});

  final MyListingProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = ProductCardTheme.forProduct(product);
    final radius = BorderRadius.circular(14.r);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 327.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductMediaThumbnail(
              product: product,
              width: 327.w,
              height: 153.h,
              alignment: Alignment.bottomCenter,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
              openPreviewOnTap: true,
              accentColor: theme.accent,
            ),
            InkWell(
              onTap: () => ProductDetailsOpener.openByProductId(
                context,
                productId: product.productId,
                seed: product,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                child: ProductCardMarketplaceLayout(
                  product: product,
                  theme: theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
