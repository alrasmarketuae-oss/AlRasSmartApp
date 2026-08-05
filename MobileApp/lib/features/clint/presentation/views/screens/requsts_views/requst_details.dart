import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/product_view_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_app_bar.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_ad_details_body.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class RequestDetailsView extends StatefulWidget {
  const RequestDetailsView({super.key, required this.product});

  final MyListingProductModel product;

  @override
  State<RequestDetailsView> createState() => _RequestDetailsViewState();
}

class _RequestDetailsViewState extends State<RequestDetailsView> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ProductViewService.trackProductView(
        widget.product.productId,
        product: widget.product,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final product = widget.product;
    final isOwnAd = ProductOwnershipHelper.isOwnedByCurrentUser(product);
    final showSubmitOfferButton =
        !AuthService.instance.isCompanyCustomerAccount;

    return Scaffold(
      backgroundColor: BookingDetailsDesign.pageBg,
      appBar: BookingDetailsAppBar(product: product),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
              child: RequestAdDetailsBody(
                product: product,
                fontFamily: fontFamily,
              ),
            ),
          ),
          if (showSubmitOfferButton)
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
                        AppRoutes.kSubmitOfferView,
                        extra: {
                          'product': product,
                          'toUserId': product.ownerId,
                        },
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
                    icon: Icon(Icons.send_rounded, size: 18.sp),
                    label: Text(
                      s.submitOffer,
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
