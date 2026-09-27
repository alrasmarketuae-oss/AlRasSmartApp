import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders matching [ChatMessageBubble] layout.
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key, this.itemCount});

  /// Limits the bubbles (e.g. inline "load older" placeholder); shrink-wraps.
  final int? itemCount;

  static const _bubbles = <({bool isMe, double widthFactor, int lines})>[
    (isMe: false, widthFactor: 0.62, lines: 2),
    (isMe: true, widthFactor: 0.48, lines: 1),
    (isMe: false, widthFactor: 0.7, lines: 3),
    (isMe: true, widthFactor: 0.55, lines: 2),
    (isMe: false, widthFactor: 0.4, lines: 1),
    (isMe: true, widthFactor: 0.66, lines: 2),
    (isMe: false, widthFactor: 0.52, lines: 1),
    (isMe: true, widthFactor: 0.38, lines: 1),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: ListView.separated(
        reverse: itemCount == null,
        shrinkWrap: itemCount != null,
        physics: const NeverScrollableScrollPhysics(),
        padding: itemCount == null
            ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h)
            : EdgeInsets.symmetric(vertical: 8.h),
        itemCount: itemCount?.clamp(1, _bubbles.length) ?? _bubbles.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final bubble = _bubbles[index];
          return _BubbleSkeleton(
            isMe: bubble.isMe,
            widthFactor: bubble.widthFactor,
            lines: bubble.lines,
            color: base,
          );
        },
      ),
    );
  }
}

class _BubbleSkeleton extends StatelessWidget {
  const _BubbleSkeleton({
    required this.isMe,
    required this.widthFactor,
    required this.lines,
    required this.color,
  });

  final bool isMe;
  final double widthFactor;
  final int lines;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lineHeight = 10.h;
    final bubbleHeight = 20.h + lines * lineHeight + (lines - 1) * 6.h;

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: widthFactor.sw,
            height: bubbleHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.r),
                topRight: Radius.circular(15.r),
                bottomLeft: Radius.circular(isMe ? 15.r : 4.r),
                bottomRight: Radius.circular(isMe ? 4.r : 15.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: 40.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ],
    );
  }
}
