import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingOfferInputWidget extends StatelessWidget {
  const BookingOfferInputWidget({super.key, required this.fontFamily});

  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<ClintCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.enterYourOffer,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontFamily: fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              s.optional,
              style: TextStyle(
                color: const Color(0xFF333333).withValues(alpha: 0.5),
                fontFamily: fontFamily,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: cubit.bookingOfferController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: s.enterYourOffer,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            hintStyle: TextStyle(
              color: const Color(0xFF333333).withValues(alpha: 0.4),
              fontFamily: fontFamily,
              fontSize: 14.sp,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Color(0xFFEAECF0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Color(0xFF3A7DC5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
