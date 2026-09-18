import 'dart:async';

import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/helpers/ai_agent_activity_mapper.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Collapsed activity history above a finished assistant reply (expand via arrow).
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
  void didUpdateWidget(covariant AiThinkingTrace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        widget.initiallyExpanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendly =
        AiAgentActivityMapper.friendlyHistory(context, widget.steps);
    if (friendly.isEmpty) return const SizedBox.shrink();

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
                      : (isAr
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded),
                  size: 16.sp,
                  color: widget.colors.mutedText,
                ),
                SizedBox(width: 2.w),
                Flexible(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.colors.mutedText,
                    ),
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
                  _PulseDot(
                    color: LightColor.defaultColor.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Container(
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
                for (var i = 0; i < friendly.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == friendly.length - 1 ? 0 : 6.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              EdgeInsetsDirectional.only(top: 2.h, end: 6.w),
                          child: widget.live && i == friendly.length - 1
                              ? _PulseDot(
                                  color: LightColor.defaultColor
                                      .withValues(alpha: 0.85),
                                )
                              : Icon(
                                  Icons.check_circle_outline,
                                  size: 13.sp,
                                  color: widget.colors.pathCode
                                      .withValues(alpha: 0.9),
                                ),
                        ),
                        Expanded(
                          child: Text(
                            friendly[i],
                            style: TextStyle(
                              fontSize: 11.sp,
                              height: 1.35,
                              fontWeight: FontWeight.w400,
                              color: widget.colors.thinkingText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

/// Live agent activity status while a request is in flight.
class AiAgentActivityBubble extends StatefulWidget {
  const AiAgentActivityBubble({
    super.key,
    required this.steps,
    required this.colors,
    this.startedAt,
  });

  final List<String> steps;
  final AiChatColors colors;
  final DateTime? startedAt;

  @override
  State<AiAgentActivityBubble> createState() => _AiAgentActivityBubbleState();
}

class _AiAgentActivityBubbleState extends State<AiAgentActivityBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _stillWorkingTimer;
  AiAgentActivityKind _kind = AiAgentActivityKind.processing;
  bool _showingStillWorking = false;
  String? _lastRawStep;

  static const _stillWorkingAfter = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _applySteps(widget.steps);
    _armStillWorkingTimer();
  }

  @override
  void didUpdateWidget(covariant AiAgentActivityBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.steps, widget.steps)) {
      _applySteps(widget.steps);
      _armStillWorkingTimer();
    }
  }

  @override
  void dispose() {
    _stillWorkingTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _applySteps(List<String> steps) {
    if (steps.isEmpty) {
      _kind = AiAgentActivityKind.processing;
      _showingStillWorking = false;
      _lastRawStep = null;
      return;
    }
    final latest = steps.last;
    if (latest == _lastRawStep && _showingStillWorking) return;
    final classified = AiAgentActivityMapper.classify(latest) ??
        AiAgentActivityKind.processing;
    _kind = classified;
    _showingStillWorking = false;
    _lastRawStep = latest;
  }

  void _armStillWorkingTimer() {
    _stillWorkingTimer?.cancel();
    _stillWorkingTimer = Timer(_stillWorkingAfter, () {
      if (!mounted || _showingStillWorking) return;
      setState(() {
        _showingStillWorking = true;
        _kind = AiAgentActivityKind.stillWorking;
      });
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final label = AiAgentActivityMapper.labelFor(context, _kind);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AiAvatar(size: 26),
          SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.45, end: 1).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: LightColor.defaultColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        label,
                        key: ValueKey(label),
                        style: TextStyle(
                          color: widget.colors.thinkingText,
                          fontSize: 13.sp,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
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

/// Backward-compatible alias for existing call sites.
typedef AiThinkingBubble = AiAgentActivityBubble;

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12.w,
      height: 12.w,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
