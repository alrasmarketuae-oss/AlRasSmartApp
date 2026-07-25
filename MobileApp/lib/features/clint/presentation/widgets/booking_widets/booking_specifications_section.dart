import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_bullet_row.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_section_title.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingSpecificationsSection extends StatelessWidget {
  const BookingSpecificationsSection({
    super.key,
    required this.product,
    required this.fontFamily,
  });

  final MyListingProductModel product;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final items = BookingDetailsMapper.specificationItems(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingDetailsSectionTitle(
          title: S.of(context).specifications,
          fontFamily: fontFamily,
        ),
        SizedBox(height: 8.h),
        BookingDetailsCard(
          children: items
              .map(
                (item) => BookingBulletRow(
                  text: item,
                  fontFamily: fontFamily,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
