import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdFieldColumn extends StatelessWidget {
  const CreateAdFieldColumn({
    super.key,
    required this.label,
    required this.child,
    this.flex = 1,
    this.expandField = false,
  });

  final String label;
  final Widget child;
  final int flex;
  final bool expandField;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          SizedBox(height: 6.h),
          if (expandField)
            Expanded(
              child: SizedBox(width: double.infinity, child: child),
            )
          else
            SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
