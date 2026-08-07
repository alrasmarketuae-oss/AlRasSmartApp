import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendBookingQuantitySection extends StatelessWidget {
  const SendBookingQuantitySection({
    super.key,
    required this.product,
    required this.fontFamily,
    required this.quantityController,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.onQuantityChanged,
    this.yourOffer,
    this.unitPrice = 0,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final TextEditingController quantityController;
  final String selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final VoidCallback onQuantityChanged;
  final String? yourOffer;
  final double unitPrice;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final unitLabel = selectedUnit.isEmpty ? 'Ton' : selectedUnit;
    final quantity =
        ThousandsNumberInput.parseDouble(quantityController.text) ?? 0;
    final total = unitPrice * quantity;
    final showPrices = ProductPriceFormatter.canShowPrices;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  '${s.quantity}:',
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(allowDecimal: true),
                  ],
                  onChanged: (_) => onQuantityChanged(),
                  decoration: _fieldDecoration(
                    hint: s.quantity,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: product.unitName == "kg"
                      ? "Kilogram"
                      : (product.unitName ?? ""),
                  readOnly: true,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    color: const Color(0xFF374151),
                  ),
                  decoration: _fieldDecoration(
                    hint: unitLabel,
                    fontFamily: fontFamily,
                  ).copyWith(
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (yourOffer == null && showPrices) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ProductPriceText.unitPrice(
                    product,
                    amountStyle: TextStyle(
                      color: const Color(0xFF2E7D32),
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showPrices) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.total,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontFamily: fontFamily,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ProductPriceText(
                  amount: ThousandsNumberInput.format(total),
                  currency: ProductPriceFormatter.currencyCode(product),
                  amountStyle: TextStyle(
                    color: const Color(0xFF3A7DC5),
                    fontFamily: fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  iconSize: 14,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required String fontFamily,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      hintStyle: TextStyle(
        color: const Color(0xFF333333).withValues(alpha: 0.4),
        fontFamily: fontFamily,
        fontSize: 14.sp,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
      ),
    );
  }
}
