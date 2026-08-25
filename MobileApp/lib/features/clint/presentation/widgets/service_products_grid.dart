import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/offer_product_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product%20_card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standard 2-column product grid for service pages (offers stay 2 cols on tablet).
class ServiceProductsGrid extends StatelessWidget {
  const ServiceProductsGrid({
    super.key,
    required this.products,
    this.useOfferCard = false,
    this.preferRetailChannel = false,
  });

  final List<MyListingProductModel> products;
  final bool useOfferCard;

  /// Retail service tab: hybrids open with Add to Cart.
  final bool preferRetailChannel;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        ProductGridLayout.categoryHorizontalPadding(context);
    final crossSpacing = 16.w;
    final mainSpacing = 16.h;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            24.w,
            8.h,
            24.w,
            24.h + kBottomNavigationBarHeight,
          ),
          sliver: SliverGrid(
            gridDelegate: useOfferCard
                ? ProductGridLayout.offerDelegate(
                    context,
                    horizontalPadding: horizontalPadding,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                  )
                : ProductGridLayout.delegate(
                    context,
                    horizontalPadding: horizontalPadding,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                  ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                final title = product.productName.isEmpty
                    ? 'Product'
                    : product.productName;
                if (useOfferCard) {
                  return OfferProductCard(
                    title: title,
                    product: product,
                  );
                }
                return ProductCard(
                  title: title,
                  product: product,
                  preferRetailChannel: preferRetailChannel,
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }
}
