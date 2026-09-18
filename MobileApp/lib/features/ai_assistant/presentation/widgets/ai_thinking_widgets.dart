import 'dart:async';
import 'dart:math' as math;

import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:alrasmarket/generated/l10n.dart';
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
    final steps = widget.steps
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (steps.isEmpty) return const SizedBox.shrink();

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
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isAr
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: widget.colors.mutedText,
                  ),
                ),
                SizedBox(width: 2.w),
                Flexible(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
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
            margin: EdgeInsetsDirectional.only(start: 2.w, top: 6.h),
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.colors.thinkingPanelBg,
                  widget.colors.thinkingPanelBg.withValues(alpha: 0.72),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: widget.colors.thinkingPanelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : 8.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              EdgeInsetsDirectional.only(top: 2.h, end: 8.w),
                          child: widget.live && i == steps.length - 1
                              ? _PulseDot(
                                  color: LightColor.defaultColor
                                      .withValues(alpha: 0.9),
                                )
                              : Icon(
                                  Icons.check_circle_rounded,
                                  size: 14.sp,
                                  color: LightColor.defaultColor
                                      .withValues(alpha: 0.85),
                                ),
                        ),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.4,
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
          duration: const Duration(milliseconds: 240),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

/// Live cinematic thinking panel — reveals ~10 narrative lines while working.
class AiAgentActivityBubble extends StatefulWidget {
  const AiAgentActivityBubble({
    super.key,
    required this.steps,
    required this.colors,
    this.startedAt,
    this.narrative = const [],
  });

  /// Already-revealed thinking lines (driven by the parent).
  final List<String> steps;
  final AiChatColors colors;
  final DateTime? startedAt;

  /// Full planned narrative for this request (used if [steps] is empty).
  final List<String> narrative;

  @override
  State<AiAgentActivityBubble> createState() => _AiAgentActivityBubbleState();
}

class _AiAgentActivityBubbleState extends State<AiAgentActivityBubble>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  late final AnimationController _border;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _border = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AiAgentActivityBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps.length > oldWidget.steps.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    _border.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _visibleSteps {
    if (widget.steps.isNotEmpty) return widget.steps;
    if (widget.narrative.isNotEmpty) return [widget.narrative.first];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final steps = _visibleSteps;
    final elapsed = widget.startedAt == null
        ? null
        : DateTime.now().difference(widget.startedAt!).inMilliseconds;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAvatar(size: 26),
          SizedBox(width: 8.w),
          Flexible(
            child: AnimatedBuilder(
              animation: _border,
              builder: (context, child) {
                final t = _border.value;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: Radius.circular(16.r),
                      topEnd: Radius.circular(16.r),
                      bottomEnd: Radius.circular(16.r),
                      bottomStart: Radius.circular(4.r),
                    ),
                    gradient: SweepGradient(
                      startAngle: t * math.pi * 2,
                      colors: [
                        LightColor.defaultColor.withValues(alpha: 0.15),
                        LightColor.defaultColor.withValues(alpha: 0.75),
                        const Color(0xFF38BDF8).withValues(alpha: 0.55),
                        LightColor.defaultColor.withValues(alpha: 0.15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LightColor.defaultColor.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(1.4),
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                decoration: BoxDecoration(
                  color: widget.colors.assistantBubbleBg,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(15.r),
                    topEnd: Radius.circular(15.r),
                    bottomEnd: Radius.circular(15.r),
                    bottomStart: Radius.circular(3.5.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.4, end: 1).animate(
                            CurvedAnimation(
                              parent: _pulse,
                              curve: Curves.easeInOut,
                            ),
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
                        SizedBox(width: 8.w),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _shimmer,
                            builder: (context, _) {
                              return ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) {
                                  final t = _shimmer.value;
                                  return LinearGradient(
                                    begin: Alignment(-1 + 2 * t, 0),
                                    end: Alignment(1 + 2 * t, 0),
                                    colors: [
                                      widget.colors.mutedText,
                                      LightColor.defaultColor,
                                      widget.colors.mutedText,
                                    ],
                                    stops: const [0.25, 0.5, 0.75],
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  s.aiAgentActivityTitle,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (elapsed != null)
                          Text(
                            isAr
                                ? '${(elapsed / 1000).toStringAsFixed(1)} ث'
                                : '${(elapsed / 1000).toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: widget.colors.mutedText,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 220.h),
                      child: steps.isEmpty
                          ? Text(
                              isAr ? 'جارٍ التحضير…' : 'Getting ready…',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: widget.colors.thinkingText,
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: steps.length,
                              itemBuilder: (context, index) {
                                final isLatest = index == steps.length - 1;
                                return _ThinkingLine(
                                  key: ValueKey(
                                    'think-$index-${steps[index]}',
                                  ),
                                  text: steps[index],
                                  colors: widget.colors,
                                  isLatest: isLatest,
                                  index: index,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingLine extends StatelessWidget {
  const _ThinkingLine({
    super.key,
    required this.text,
    required this.colors,
    required this.isLatest,
    required this.index,
  });

  final String text;
  final AiChatColors colors;
  final bool isLatest;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + math.min(index, 6) * 20),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 7.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: 2.h, end: 8.w),
              child: isLatest
                  ? _PulseDot(
                      color: LightColor.defaultColor.withValues(alpha: 0.95),
                    )
                  : Icon(
                      Icons.check_circle_rounded,
                      size: 14.sp,
                      color: LightColor.defaultColor.withValues(alpha: 0.8),
                    ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  height: 1.4,
                  fontWeight: isLatest ? FontWeight.w600 : FontWeight.w400,
                  color: isLatest
                      ? const Color(0xFF1F2937)
                      : colors.thinkingText,
                ),
              ),
            ),
          ],
        ),
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
