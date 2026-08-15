import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendBookingProductCard extends StatelessWidget {
  const SendBookingProductCard({
    super.key,
    required this.product,
    required this.fontFamily,
  });

  final MyListingProductModel product;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductMediaThumbnail(
                product: product,
                width: 72.w,
                height: 72.h,
                borderRadius: BorderRadius.circular(8.r),
                openPreviewOnTap: false,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  product.productName.isEmpty
                      ? 'Whole Black Pepper'
                      : product.productName,
                  style: TextStyle(
                    color: ProductGridLayout.productCardTitleColor(context),
                    fontFamily: fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            BookingDetailsMapper.descriptionText(product),
            style: TextStyle(
              color: AppColors.subtitle(context),
              fontFamily: fontFamily,
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.iconSoftColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${S.of(context).specifications}: ",
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  product.description,
                  style: TextStyle(
                    color: AppColors.subtitle(context),
                    fontFamily: fontFamily,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
