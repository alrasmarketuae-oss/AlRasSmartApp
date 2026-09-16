import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/helpers/ai_chat_heuristics.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiThinkingTrace extends StatefulWidget {
  const AiThinkingTrace({
    super.key,
    required this.steps,
    required this.title,
    required this.colors,
    this.initiallyExpanded = false,
    this.live = false,
    this.durationMs,
  });

  final List<String> steps;
  final String title;
  final AiChatColors colors;
  final bool initiallyExpanded;
  final bool live;
  final int? durationMs;

  @override
  State<AiThinkingTrace> createState() => _AiThinkingTraceState();
}

class _AiThinkingTraceState extends State<AiThinkingTrace> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final durationLabel = widget.durationMs == null
        ? null
        : (isAr
            ? '(${((widget.durationMs! / 1000).toStringAsFixed(1))} ث)'
            : '(${((widget.durationMs! / 1000).toStringAsFixed(1))}s)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 16.sp,
                  color: widget.colors.mutedText,
                ),
                SizedBox(width: 2.w),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: widget.colors.mutedText,
                  ),
                ),
                if (durationLabel != null) ...[
                  SizedBox(width: 4.w),
                  Text(
                    durationLabel,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: widget.colors.mutedText,
                    ),
                  ),
                ],
                if (widget.live) ...[
                  SizedBox(width: 6.w),
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LightColor.defaultColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: EdgeInsetsDirectional.only(start: 4.w, top: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: widget.colors.thinkingPanelBg,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: widget.colors.thinkingPanelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: 2.h, end: 6.w),
                          child: widget.live && i == widget.steps.length - 1
                              ? SizedBox(
                                  width: 12.w,
                                  height: 12.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: LightColor.defaultColor.withValues(alpha: 0.85),
                                  ),
                                )
                              : Icon(
                                  Icons.check_circle_outline,
                                  size: 13.sp,
                                  color: widget.colors.pathCode.withValues(alpha: 0.9),
                                ),
                        ),
                        Expanded(
                          child: AiThinkingStepText(
                            step: widget.steps[i],
                            colors: widget.colors,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class AiThinkingStepText extends StatelessWidget {
  const AiThinkingStepText({super.key, required this.step, required this.colors});

  final String step;
  final AiChatColors colors;

  @override
  Widget build(BuildContext context) {
    final lines = step.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          AiThinkingLineText(line: line, colors: colors),
      ],
    );
  }
}

class AiThinkingLineText extends StatelessWidget {
  const AiThinkingLineText({super.key, required this.line, required this.colors});

  final String line;
  final AiChatColors colors;

  static final RegExp _pathLine = RegExp(
    r'(product-(?:images|videos)/[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final match = _pathLine.firstMatch(line);
    if (match == null) {
      return Text(
        line,
        style: TextStyle(
          fontSize: 10.5.sp,
          height: 1.35,
          fontWeight: FontWeight.w400,
          color: colors.thinkingText,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final start = match.start;
    final end = match.end;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 10.5.sp,
          height: 1.35,
          fontWeight: FontWeight.w400,
          color: colors.thinkingText,
          fontStyle: FontStyle.italic,
        ),
        children: [
          if (start > 0) TextSpan(text: line.substring(0, start)),
          TextSpan(
            text: line.substring(start, end),
            style: TextStyle(
              color: colors.pathCode,
              fontFamily: 'monospace',
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (end < line.length) TextSpan(text: line.substring(end)),
        ],
      ),
    );
  }
}

class AiThinkingBubble extends StatefulWidget {
  const AiThinkingBubble({
    super.key,
    required this.steps,
    required this.colors,
    this.startedAt,
  });

  final List<String> steps;
  final AiChatColors colors;
  final DateTime? startedAt;

  @override
  State<AiThinkingBubble> createState() => _AiThinkingBubbleState();
}

class _AiThinkingBubbleState extends State<AiThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AiAvatar(size: 26),
          SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.colors.assistantBubbleBg,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(16.r),
                  topEnd: Radius.circular(16.r),
                  bottomEnd: Radius.circular(16.r),
                  bottomStart: Radius.circular(4.r),
                ),
                border: Border.all(color: widget.colors.assistantBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.steps.isEmpty)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            final t = (_controller.value + i * 0.2) % 1.0;
                            final opacity =
                                0.3 +
                                (0.7 *
                                        (1 - (t - 0.5).abs() * 2)
                                            .clamp(0.0, 1.0));
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: Opacity(
                                opacity: opacity,
                                child: Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: const BoxDecoration(
                                    color: LightColor.defaultColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    )
                  else
                    Directionality(
                      textDirection:
                          detectAiTextDirection(widget.steps.join(' ')),
                      child: Text(
                        widget.steps.join(' '),
                        style: TextStyle(
                          color: widget.colors.thinkingText,
                          fontSize: 13.sp,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
