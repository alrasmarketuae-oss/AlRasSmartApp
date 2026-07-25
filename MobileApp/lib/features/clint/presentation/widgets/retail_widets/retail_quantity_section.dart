import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RetailQuantitySection extends StatelessWidget {
  const RetailQuantitySection({
    super.key,
    required this.fontFamily,
    required this.quantityController,
    required this.unit,
    required this.onQuantityChanged,
    this.validator,
  });

  final String fontFamily;
  final TextEditingController quantityController;
  final String unit;
  final VoidCallback onQuantityChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final unitLabel = unit.trim().isEmpty ? '—' : unit.trim();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            onChanged: (_) => onQuantityChanged(),
            validator: validator,
            decoration: _fieldDecoration(
              hint: s.quantity,
              fontFamily: fontFamily,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFEAECF0), width: 1.5),
            ),
            child: Text(
              unitLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF333333).withValues(alpha: 0.75),
                fontFamily: fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
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
