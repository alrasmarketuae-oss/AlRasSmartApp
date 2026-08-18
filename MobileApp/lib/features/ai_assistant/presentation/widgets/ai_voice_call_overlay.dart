import 'dart:async';
import 'dart:math' as math;

import 'package:alrasmarket/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AiCallPhase { waiting, listening, thinking, speaking, muted }

class AiVoiceCallOverlay extends StatefulWidget {
  const AiVoiceCallOverlay({
    super.key,
    required this.phase,
    required this.onEndCall,
    required this.thinkingSteps,
    required this.micMuted,
    required this.micActive,
    required this.onToggleMicMute,
    required this.onToggleMic,
    this.voiceGenderLabel,
  });

  final AiCallPhase phase;
  final VoidCallback onEndCall;
  final List<String> thinkingSteps;
  final bool micMuted;
  final bool micActive;
  final VoidCallback onToggleMicMute;
  final VoidCallback onToggleMic;
  final String? voiceGenderLabel;

  @override
  State<AiVoiceCallOverlay> createState() => _AiVoiceCallOverlayState();
}

class _AiVoiceCallOverlayState extends State<AiVoiceCallOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final AnimationController _glowController;
  late final AnimationController _orbController;
  Timer? _durationTimer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  String get _formattedDuration {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _phaseColor => switch (widget.phase) {
        AiCallPhase.listening => const Color(0xFFE11D48),
        AiCallPhase.thinking => const Color(0xFFF59E0B),
        AiCallPhase.speaking => const Color(0xFF10B981),
        AiCallPhase.muted => const Color(0xFF94A3B8),
        AiCallPhase.waiting => const Color(0xFF3B82F6),
      };

  String _statusText(bool isAr) => switch (widget.phase) {
        AiCallPhase.listening =>
          isAr ? 'بيسمعك… تكلم الآن' : 'Listening… speak now',
        AiCallPhase.thinking =>
          isAr ? 'بيفكر…' : 'Thinking…',
        AiCallPhase.speaking => isAr ? 'بيتكلم…' : 'Speaking…',
        AiCallPhase.muted =>
          isAr ? 'المايك مكتوم' : 'Microphone muted',
        AiCallPhase.waiting =>
          isAr ? 'جاهز — اضغط المايك' : 'Ready — tap mic',
      };

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final statusColor = _phaseColor;
    final showWaves = widget.phase == AiCallPhase.listening ||
        widget.phase == AiCallPhase.speaking;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(_orbController.value * 2 * math.pi) * 0.3,
                    -1,
                  ),
                  end: Alignment(
                    math.sin(_orbController.value * 2 * math.pi) * 0.3,
                    1,
                  ),
                  colors: const [
                    Color(0xFF070B14),
                    Color(0xFF0F172A),
                    Color(0xFF111827),
                  ],
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(isAr),
                const Spacer(flex: 2),
                GestureDetector(
                  onTap: widget.micMuted ? null : widget.onToggleMic,
                  child: _buildCentralOrb(statusColor),
                ),
                SizedBox(height: 24.h),
                Text(
                  'allras AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                if (widget.voiceGenderLabel != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    widget.voiceGenderLabel!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Row(
                    key: ValueKey('${widget.phase}_${widget.micMuted}'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusDot(color: statusColor),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          _statusText(isAr),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _formattedDuration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: 28.h),
                if (showWaves)
                  _SoundWaveVisualizer(
                    controller: _waveController,
                    color: statusColor,
                    barCount: 44,
                    isActive: true,
                  )
                else if (widget.phase == AiCallPhase.thinking)
                  _ThinkingDotsVisualizer(
                    steps: widget.thinkingSteps,
                    color: statusColor,
                  )
                else
                  SizedBox(height: 60.h),
                const Spacer(flex: 3),
                _buildBottomControls(isAr),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isAr) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  isAr ? 'محادثة صوتية' : 'Voice Chat',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            _formattedDuration,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralOrb(Color phaseColor) {
    return SizedBox(
      width: 210.w,
      height: 210.w,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          final pulse =
              1.0 + math.sin(_pulseController.value * 2 * math.pi) * 0.07;
          final glowOpacity = 0.18 + _glowController.value * 0.22;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200.w * pulse,
                height: 200.w * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: phaseColor.withValues(alpha: glowOpacity * 0.25),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 160.w * pulse,
                height: 160.w * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      phaseColor.withValues(alpha: glowOpacity * 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
              Container(
                width: 128.w,
                height: 128.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.35),
                    colors: [
                      phaseColor.withValues(alpha: 0.35),
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withValues(alpha: glowOpacity),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(22.w),
                    child: Image.asset(
                      AppAssets.aiAgentIcon,
                      fit: BoxFit.contain,
                      color: Colors.white.withValues(alpha: 0.9),
                      colorBlendMode: BlendMode.srcATop,
                    ),
                  ),
                ),
              ),
              if (widget.micActive)
                Positioned(
                  bottom: 8.h,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record,
                            color: Colors.white, size: 10.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(bool isAr) {
    final micDisabled = widget.micMuted;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleButton(
            icon: widget.micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: isAr ? 'كتم' : 'Mute',
            color: widget.micMuted
                ? const Color(0xFFE11D48).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            iconColor:
                widget.micMuted ? const Color(0xFFE11D48) : Colors.white,
            borderColor: widget.micMuted ? const Color(0xFFE11D48) : null,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onToggleMicMute();
            },
          ),
          _CircleButton(
            icon: Icons.call_end_rounded,
            label: isAr ? 'إنهاء' : 'End',
            color: const Color(0xFFE11D48),
            iconColor: Colors.white,
            size: 68,
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onEndCall();
            },
          ),
          _CircleButton(
            icon: widget.micActive
                ? Icons.stop_rounded
                : Icons.mic_none_rounded,
            label: isAr ? 'مايك' : 'Mic',
            color: widget.micActive
                ? const Color(0xFF3B82F6)
                : Colors.white.withValues(alpha: 0.1),
            iconColor: micDisabled
                ? Colors.white.withValues(alpha: 0.25)
                : (widget.micActive ? Colors.white : Colors.white),
            borderColor: widget.micActive ? const Color(0xFF3B82F6) : null,
            onTap: micDisabled
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onToggleMic();
                  },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.size = 56,
    this.borderColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final double size;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: size.w,
              height: size.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: borderColor != null
                    ? Border.all(color: borderColor!, width: 2)
                    : null,
                boxShadow: onTap == null
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(icon, color: iconColor, size: (size * 0.4).sp),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: onTap == null ? 0.25 : 0.65),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: 9.w,
        height: 9.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _c.value * 0.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _c.value * 0.55),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundWaveVisualizer extends StatelessWidget {
  const _SoundWaveVisualizer({
    required this.controller,
    required this.color,
    this.barCount = 40,
    this.isActive = true,
  });

  final AnimationController controller;
  final Color color;
  final int barCount;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.h,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WavePainter(
                progress: controller.value,
                color: color,
                barCount: barCount,
                isActive: isActive,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.color,
    required this.barCount,
    required this.isActive,
  });

  final double progress;
  final Color color;
  final int barCount;
  final bool isActive;
  static final math.Random _rng = math.Random(42);
  static final List<double> _seeds =
      List.generate(80, (_) => _rng.nextDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (barCount * 2);
    final maxHeight = size.height * 0.85;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final seed = _seeds[i % _seeds.length];
      final wave =
          math.sin((progress * 2 * math.pi) + (i * 0.35)) * 0.5 + 0.5;
      final h = isActive
          ? maxHeight * (0.1 + seed * 0.3 + wave * 0.6)
          : maxHeight * 0.08;

      final x = (i * 2 + 0.5) * barWidth;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(x, centerY), width: barWidth * 0.7, height: h),
        Radius.circular(barWidth),
      );

      final opacity = 0.3 + wave * 0.7;
      canvas.drawRRect(
        rect,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

class _ThinkingDotsVisualizer extends StatefulWidget {
  const _ThinkingDotsVisualizer({
    required this.steps,
    required this.color,
  });

  final List<String> steps;
  final Color color;

  @override
  State<_ThinkingDotsVisualizer> createState() =>
      _ThinkingDotsVisualizerState();
}

class _ThinkingDotsVisualizerState extends State<_ThinkingDotsVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final offset = (i * 0.15);
                  final v = math.sin(
                      (_dotController.value + offset) * 2 * math.pi);
                  final scale = 0.4 + (v * 0.5 + 0.5) * 0.6;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 9.w,
                        height: 9.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color
                              .withValues(alpha: 0.3 + scale * 0.7),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color
                                  .withValues(alpha: scale * 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          if (widget.steps.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                widget.steps.last,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.sp,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
