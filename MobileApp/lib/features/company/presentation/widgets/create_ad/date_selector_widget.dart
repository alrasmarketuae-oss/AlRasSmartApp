import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DateSelectorWidget extends StatelessWidget {
  const DateSelectorWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.labelText = 'Required Delivery Date',
    this.hintText = 'Enter Date',
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String labelText;
  final String hintText;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = selectedDate;
    final firstDate = selected != null && selected.isBefore(now)
        ? DateTime(selected.year, selected.month, selected.day)
        : DateTime(now.year, now.month, now.day);
    final initialDate = selected ?? now;
    final safeInitial = initialDate.isBefore(firstDate) ? firstDate : initialDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: CreateAdDesign.cardBg,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: CreateAdDesign.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                      : hintText,
                  style: TextStyle(
                    color: selectedDate != null
                        ? CreateAdDesign.text
                        : CreateAdDesign.muted,
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18.sp,
                  color: CreateAdDesign.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
