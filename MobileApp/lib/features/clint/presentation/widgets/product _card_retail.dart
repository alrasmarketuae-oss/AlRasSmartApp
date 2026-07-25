import 'package:alrasmarket/features/clint/presentation/widgets/product%20_card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';

class ProductCardRetail extends StatelessWidget {
  const ProductCardRetail({super.key, required this.product, this.onOrderTap});

  final MyListingProductModel product;
  final VoidCallback? onOrderTap;

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      title: product.productName,
      product: product,
      onOrderTap: onOrderTap,
      preferRetailChannel: true,
    );
  }
}
