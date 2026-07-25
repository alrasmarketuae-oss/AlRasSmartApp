import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/product_view_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_ad_details_body.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_app_bar.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/category_ad_details_body.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_sold_out_label.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BookingDetailsView extends StatefulWidget {
  const BookingDetailsView({super.key, required this.product});

  final MyListingProductModel product;

  @override
  State<BookingDetailsView> createState() => _BookingDetailsViewState();
}

class _BookingDetailsViewState extends State<BookingDetailsView> {
  late MyListingProductModel _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    unawaited(
      ProductViewService.trackProductView(
        widget.product.productId,
        product: widget.product,
      ),
    );
    _refreshFromApi();
  }

  Future<void> _refreshFromApi() async {
    final id = widget.product.productId.trim();
    if (id.isEmpty) return;

    final fresh = await ProductDetailsOpener.fetchPublicProductById(id);
    if (!mounted || fresh == null) return;

    setState(() => _product = fresh);
  }

  bool get _isBookingType => _product.isBookingProduct;

  /// Category / wholesale catalog (not Booking type).
  bool get _useCategoryLayout =>
      _product.isCategoryCatalogProduct && !_isBookingType;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final soldOut = ProductStock.isSoldOut(_product);
    final isOwnAd = ProductOwnershipHelper.isOwnedByCurrentUser(_product);

    return Scaffold(
      backgroundColor: BookingDetailsDesign.pageBg,
      appBar: BookingDetailsAppBar(product: _product),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (soldOut) ...[
                    ProductSoldOutLabel(fontFamily: fontFamily),
                    SizedBox(height: 12.h),
                  ],
                  if (_useCategoryLayout)
                    CategoryAdDetailsBody(
                      product: _product,
                      fontFamily: fontFamily,
                    )
                  else
                    BookingAdDetailsBody(
                      product: _product,
                      fontFamily: fontFamily,
                    ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
          if (!soldOut)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isOwnAd) {
                        AppToast.showError(context, s.cannotOrderOwnProduct);
                        return;
                      }
                      context.push(
                        AppRoutes.kSendBookingOrderView,
                        extra: {'product': _product},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BookingDetailsDesign.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(Icons.shopping_cart_outlined, size: 18.sp),
                    label: Text(
                      s.purchaseOrder,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
