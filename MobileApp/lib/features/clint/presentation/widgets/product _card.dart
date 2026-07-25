import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_card_marketplace_layout.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_card_theme.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    this.onOrderTap,
    required this.product,
    this.preferRetailChannel = false,
  });

  final String title;
  final VoidCallback? onOrderTap;
  final MyListingProductModel product;

  /// From retail feed: open hybrid as Add to Cart with retail pricing.
  /// Personal accounts always prefer retail cart when possible.
  final bool preferRetailChannel;

  @override
  Widget build(BuildContext context) {
    final theme = ProductCardTheme.forProduct(product);
    final radius = BorderRadius.circular(14.r);
    final useRetailChannel = preferRetailChannel ||
        AuthService.instance.isPersonalCustomerAccount;

    void openDetails() {
      if (onOrderTap != null) {
        onOrderTap!();
        return;
      }
      ProductDetailsOpener.openByProductId(
        context,
        productId: product.productId,
        preferRetailChannel: useRetailChannel,
        seed: product,
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductMediaThumbnail(
              product: product,
              width: double.infinity,
              height: ProductGridLayout.cardImageDisplayHeight(context),
              alignment: Alignment.bottomCenter,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
              openPreviewOnTap: true,
              accentColor: theme.accent,
            ),
            Expanded(
              child: InkWell(
                onTap: openDetails,
                child: Padding(
                  padding: ProductGridLayout.cardContentInsets(context),
                  child: ProductCardMarketplaceLayout(
                    product: product,
                    title: title,
                    fillHeight: true,
                    theme: theme,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
