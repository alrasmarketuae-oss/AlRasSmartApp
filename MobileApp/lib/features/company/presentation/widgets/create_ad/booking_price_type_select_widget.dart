import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/models/booking_price_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingPriceTypeSelectWidget extends StatelessWidget {
  const BookingPriceTypeSelectWidget({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final BookingPriceType? selectedType;
  final ValueChanged<BookingPriceType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final label = isAr ? 'نوع سعر البوكينج' : 'Booking Price Type';
    final hint = isAr ? 'اختر نوع السعر' : 'Select price type';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CreateAdFieldIcon(Icons.local_shipping_outlined),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: CreateAdDesign.text,
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<BookingPriceType>(
          value: selectedType,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14.sp,
              color: CreateAdDesign.muted,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: CreateAdDesign.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: CreateAdDesign.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: CreateAdDesign.brand),
            ),
          ),
          style: TextStyle(
            color: CreateAdDesign.text,
            fontFamily: fontFamily,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          items: BookingPriceType.values
              .map(
                (type) => DropdownMenuItem<BookingPriceType>(
                  value: type,
                  child: Text(type.apiValue),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
