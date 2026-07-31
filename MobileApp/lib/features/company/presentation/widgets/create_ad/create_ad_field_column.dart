import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdFieldColumn extends StatelessWidget {
  const CreateAdFieldColumn({
    super.key,
    required this.label,
    required this.child,
    this.flex = 1,
    this.expandField = false,
    this.labelInfoMessage,
  });

  final String label;
  final Widget child;
  final int flex;
  final bool expandField;
  /// When set, shows a small "!" next to the label; tap reveals this tip.
  final String? labelInfoMessage;

  @override
  Widget build(BuildContext context) {
    final tip = labelInfoMessage?.trim();
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
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
              ),
              if (tip != null && tip.isNotEmpty) ...[
                SizedBox(width: 2.w),
                Tooltip(
                  message: tip,
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: false,
                  waitDuration: Duration.zero,
                  showDuration: const Duration(seconds: 3),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 14.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
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
