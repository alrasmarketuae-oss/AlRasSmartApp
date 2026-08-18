import 'dart:async';
import 'dart:math' as math;

import 'package:alrasmarket/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AiCallPhase { listening, thinking, speaking }

class AiVoiceCallOverlay extends StatefulWidget {
  const AiVoiceCallOverlay({
    super.key,
    required this.phase,
    required this.onEndCall,
    required this.thinkingSteps,
    this.voiceGenderLabel,
  });

  final AiCallPhase phase;
  final VoidCallback onEndCall;
  final List<String> thinkingSteps;
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

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final statusText = switch (widget.phase) {
      AiCallPhase.listening => isAr ? 'بيسمعك…' : 'Listening…',
      AiCallPhase.thinking => isAr ? 'بيفكر…' : 'Thinking…',
      AiCallPhase.speaking => isAr ? 'بيتكلم…' : 'Speaking…',
    };
    final statusColor = switch (widget.phase) {
      AiCallPhase.listening => const Color(0xFFE11D48),
      AiCallPhase.thinking => const Color(0xFFF59E0B),
      AiCallPhase.speaking => const Color(0xFF10B981),
    };

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
                    Color(0xFF0A0E1A),
                    Color(0xFF0D1B2A),
                    Color(0xFF0A0E1A),
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
                _buildCentralOrb(statusColor),
                SizedBox(height: 28.h),
                Text(
                  'allras AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    key: ValueKey(widget.phase),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusDot(color: statusColor),
                      SizedBox(width: 6.w),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _formattedDuration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: 24.h),
                if (widget.phase == AiCallPhase.listening ||
                    widget.phase == AiCallPhase.speaking)
                  _SoundWaveVisualizer(
                    controller: _waveController,
                    color: statusColor,
                    barCount: 40,
                    isActive: true,
                  ),
                if (widget.phase == AiCallPhase.thinking)
                  _ThinkingDotsVisualizer(
                    steps: widget.thinkingSteps,
                    color: statusColor,
                  ),
                const Spacer(flex: 3),
                _buildBottomControls(isAr),
                SizedBox(height: 20.h),
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
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
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
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            _formattedDuration,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
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
      width: 200.w,
      height: 200.w,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          final pulse = 1.0 + math.sin(_pulseController.value * 2 * math.pi) * 0.08;
          final glowOpacity = 0.15 + _glowController.value * 0.2;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring 3
              Container(
                width: 200.w * pulse,
                height: 200.w * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: phaseColor.withValues(alpha: glowOpacity * 0.2),
                    width: 1,
                  ),
                ),
              ),
              // Outer glow ring 2
              Container(
                width: 170.w * pulse,
                height: 170.w * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: phaseColor.withValues(alpha: glowOpacity * 0.35),
                    width: 1.5,
                  ),
                ),
              ),
              // Outer glow ring 1
              Container(
                width: 145.w * pulse,
                height: 145.w * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      phaseColor.withValues(alpha: glowOpacity * 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              // Main orb
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.3),
                    colors: [
                      phaseColor.withValues(alpha: 0.3),
                      const Color(0xFF1A1F35),
                      const Color(0xFF0D1220),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withValues(alpha: glowOpacity),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Image.asset(
                      AppAssets.aiAgentIcon,
                      fit: BoxFit.contain,
                      color: Colors.white.withValues(alpha: 0.85),
                      colorBlendMode: BlendMode.srcATop,
                    ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute placeholder (disabled for now)
          _CircleButton(
            icon: Icons.mic_off_rounded,
            label: isAr ? 'كتم' : 'Mute',
            color: Colors.white.withValues(alpha: 0.08),
            iconColor: Colors.white.withValues(alpha: 0.3),
            onTap: null,
          ),
          // End call
          _CircleButton(
            icon: Icons.call_end_rounded,
            label: isAr ? 'إنهاء' : 'End',
            color: const Color(0xFFE11D48),
            iconColor: Colors.white,
            size: 64,
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onEndCall();
            },
          ),
          // Speaker placeholder
          _CircleButton(
            icon: Icons.volume_up_rounded,
            label: isAr ? 'سماعة' : 'Speaker',
            color: Colors.white.withValues(alpha: 0.08),
            iconColor: Colors.white.withValues(alpha: 0.3),
            onTap: null,
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
    this.size = 52,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size.w,
            height: size.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: (size * 0.42).sp),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
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
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _c.value * 0.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _c.value * 0.5),
              blurRadius: 6,
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
      height: 60.h,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
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
      final wave = math.sin((progress * 2 * math.pi) + (i * 0.35)) * 0.5 + 0.5;
      final h = isActive
          ? maxHeight * (0.1 + seed * 0.3 + wave * 0.6)
          : maxHeight * 0.08;

      final x = (i * 2 + 0.5) * barWidth;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, centerY), width: barWidth * 0.7, height: h),
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
      height: 60.h,
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
                        width: 8.w,
                        height: 8.w,
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
            Text(
              widget.steps.last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
