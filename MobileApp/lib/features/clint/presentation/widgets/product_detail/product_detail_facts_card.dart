import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_card.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_copy_code.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ProductDetailFactsMode {
  retail,
  booking,
  request,
  offer,
}

class ProductDetailInfoRow extends StatelessWidget {
  const ProductDetailInfoRow({
    super.key,
    required this.label,
    required this.fontFamily,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = value?.trim() ?? '';
    if (valueWidget == null && resolvedValue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF333333).withValues(alpha: 0.7),
                fontFamily: fontFamily,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 10,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: valueWidget ??
                  Text(
                    resolvedValue,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailFactsCard extends StatelessWidget {
  const ProductDetailFactsCard({
    super.key,
    required this.product,
    required this.fontFamily,
    required this.mode,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final ProductDetailFactsMode mode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final unit = product.unitName.trim();
    final rows = <Widget>[];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    void addRow({
      required String label,
      String? value,
      Widget? valueWidget,
    }) {
      if (valueWidget == null && (value == null || value.trim().isEmpty)) {
        return;
      }
      rows.add(
        ProductDetailInfoRow(
          label: label,
          value: value,
          valueWidget: valueWidget,
          fontFamily: fontFamily,
        ),
      );
    }

    switch (mode) {
      case ProductDetailFactsMode.request:
        addRow(label: s.requiredQuantity, value: _quantityValue(s));
      case ProductDetailFactsMode.booking:
        addRow(label: s.availableQuantity, value: _quantityValue(s));
      case ProductDetailFactsMode.retail:
      case ProductDetailFactsMode.offer:
        addRow(label: s.availableQuantity, value: _quantityValue(s));
    }

    if (ProductPriceFormatter.canShowPrices &&
        ProductPriceFormatter.amount(product).isNotEmpty) {
      addRow(
        label: _priceLabel(s, unit),
        valueWidget: ProductPriceText.fromProduct(
          product,
          amountStyle: TextStyle(
            color: const Color(0xFF619D50),
            fontFamily: fontFamily,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          matchCurrencyToAmount: true,
        ),
      );
    }

    if (ProductPriceTypeLabel.appliesTo(product) ||
        mode == ProductDetailFactsMode.offer ||
        mode == ProductDetailFactsMode.request) {
      final priceType = ProductPriceTypeLabel.fromProduct(product, isAr: isAr);
      addRow(
        label: s.requestFulfillment,
        value: priceType.isNotEmpty ? priceType : '—',
      );
    }

    final packaging = RequestDetailsMapper.packagingDisplay(
      product,
      s,
      isAr: isAr,
    );
    if (packaging.isNotEmpty) {
      addRow(
        label: isAr ? 'التعبئة' : 'Packing',
        value: packaging,
      );
    }

    if (mode != ProductDetailFactsMode.retail) {
      addRow(
        label: s.negotiable,
        value: product.isNegotiable
            ? s.negotiable
            : (isAr ? 'لا — سعر ثابت' : 'No — fixed price'),
      );
    }

    if (mode == ProductDetailFactsMode.booking) {
      final category = product.categoryName.trim();
      if (category.isNotEmpty && category != '—') {
        addRow(label: s.category, value: category);
      } else {
        addRow(
          label: s.category,
          value: isAr ? 'كل التصنيفات' : 'All categories',
        );
      }
      final typeName = product.productTypeName.trim();
      if (typeName.isNotEmpty) {
        addRow(
          label: isAr ? 'نوع الإعلان' : 'Ad type',
          value: typeName,
        );
      }
    }

    final productCode = product.productCode.trim();
    if (productCode.isNotEmpty) {
      addRow(
        label: s.productCode,
        valueWidget: ProductDetailCopyCode(
          code: productCode,
          fontFamily: fontFamily,
          isAr: isAr,
        ),
      );
    }

    final postedAt = product.createdAt.trim();
    if (postedAt.isNotEmpty) {
      addRow(
        label: isAr ? 'تاريخ ووقت الإضافة' : 'Posted date & time',
        value: RelativeTimeFormatter.format(s, postedAt),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.adDetails,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        SizedBox(height: 8.h),
        BookingDetailsCard(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: const Color(0xFFEAECF0).withValues(alpha: 0.9),
                ),
              rows[i],
            ],
          ],
        ),
      ],
    );
  }

  String _quantityValue(S s) {
    if (ProductStock.isSoldOut(product)) {
      return s.soldOut;
    }
    final qty = product.quantity.trim();
    if (qty.isEmpty) return '';
    return ProductQuantityFormatter.quantityWithUnit(
      quantityText: qty,
      unitName: product.unitName,
      s: s,
    );
  }

  String _priceLabel(S s, String unit) {
    switch (mode) {
      case ProductDetailFactsMode.request:
        return CreateAdPriceLabels.targetPricePerUnitLabel(s, unit);
      case ProductDetailFactsMode.offer:
        return CreateAdPriceLabels.offerPricePerUnitLabel(s, unit);
      case ProductDetailFactsMode.retail:
      case ProductDetailFactsMode.booking:
        return CreateAdPriceLabels.pricePerUnitLabel(s, unit);
    }
  }
}
