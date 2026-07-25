import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_sold_out_label.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingPurchaseOrderButton extends StatelessWidget {
  const BookingPurchaseOrderButton({
    super.key,
    this.onPressed,
    this.product,
  });

  final VoidCallback? onPressed;
  final MyListingProductModel? product;

  @override
  Widget build(BuildContext context) {
    final soldOut = product != null && ProductStock.isSoldOut(product!);
    if (soldOut) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
        child: const ProductSoldOutLabel(),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: PrimaryButton(
        text: S.of(context).purchaseOrder,
        onPressed: onPressed ?? () {},
        height: 48.h,
        borderRadius: 8.r,
        backgroundColor: const Color(0xFF3A7DC5),
      ),
    );
  }
}
