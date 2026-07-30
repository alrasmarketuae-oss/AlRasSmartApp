import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_share_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_bookmark_button.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BookingDetailsAppBar({super.key, required this.product});

  final MyListingProductModel product;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return AppBar(
      backgroundColor: BookingDetailsDesign.brand,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Text(
        s.productDetails,
        style: TextStyle(
          color: Colors.white,
          fontFamily: fontFamily,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Builder(
          builder: (buttonContext) => IconButton(
            onPressed: () =>
                ProductShareHelper.shareProduct(buttonContext, product),
            tooltip: s.shareProduct,
            icon: Icon(Icons.ios_share_rounded, size: 20.sp),
          ),
        ),
        ProductBookmarkButton(
          productId: product.productId,
          color: Colors.white,
        ),
      ],
    );
  }
}
