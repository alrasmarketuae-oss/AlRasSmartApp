import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product _card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiProductListings extends StatelessWidget {
  const AiProductListings({super.key, required this.products});

  final List<MyListingProductModel> products;

  static List<MyListingProductModel> parse(dynamic raw) {
    if (raw is! List) return const [];
    final items = <MyListingProductModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final product = MyListingProductModel.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (product.productId.trim().isEmpty) continue;
      items.add(product);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 10.w;
          final cellWidth = (constraints.maxWidth - spacing) / 2;
          final cellHeight = ProductGridLayout.estimatedCardHeight(context);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio:
                  cellHeight <= 0 ? 0.62 : cellWidth / cellHeight,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                title: product.productName,
                product: product,
                preferRetailChannel: product.preferRetailFromSearchListing,
              );
            },
          );
        },
      ),
    );
  }
}
