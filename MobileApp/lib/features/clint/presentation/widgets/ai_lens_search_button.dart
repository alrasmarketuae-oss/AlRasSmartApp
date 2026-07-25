import 'dart:math' as math;

import 'package:alrasmarket/core/utils/assets.dart';
import 'package:flutter/material.dart';

class AiLensSearchButton extends StatefulWidget {
  const AiLensSearchButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.size,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  State<AiLensSearchButton> createState() => _AiLensSearchButtonState();
}

class _AiLensSearchButtonState extends State<AiLensSearchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = size * 0.18;
    return Tooltip(
      message: widget.tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NeuralNetworkPainter(
                      progress: _controller.value,
                      compact: true,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius),
                    onTap: widget.onPressed,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF42D4FF).withValues(alpha: 0.22),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        AppAssets.aiLensSearchIcon,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NeuralNetworkPainter extends CustomPainter {
  _NeuralNetworkPainter({
    required this.progress,
    this.compact = false,
  });

  final double progress;
  final bool compact;

  static const _nodeColors = [
    Color(0xFF59E390),
    Color(0xFF42D4FF),
    Color(0xFF8A7DFF),
    Color(0xFFFF3D81),
    Color(0xFFFF8C42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * (compact ? 0.48 : 0.42);
    const nodeCount = 6;

    final nodes = List.generate(nodeCount, (i) {
      final angle = (i / nodeCount) * 2 * math.pi + progress * 2 * math.pi;
      final wobble = math.sin(progress * 2 * math.pi + i * 1.3) * (compact ? 2 : 4);
      final r = radius + wobble;
      return Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
    });

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.8 : 1.2;

    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist > radius * 1.35) continue;
        final pulse = (math.sin(progress * 2 * math.pi + i + j) + 1) / 2;
        final color = _nodeColors[(i + j) % _nodeColors.length];
        linePaint.color = color.withValues(alpha: 0.15 + pulse * 0.45);
        canvas.drawLine(nodes[i], nodes[j], linePaint);
      }
    }

    for (var i = 0; i < nodes.length; i++) {
      final pulse = (math.sin(progress * 2 * math.pi + i * 0.9) + 1) / 2;
      final color = _nodeColors[i % _nodeColors.length];
      final nodeRadius = (compact ? 1.4 : 2.2) + pulse * (compact ? 1.0 : 1.8);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25 + pulse * 0.35)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          compact ? 2 : 4,
        );
      canvas.drawCircle(nodes[i], nodeRadius + (compact ? 1.5 : 3), glowPaint);

      final nodePaint = Paint()..color = color.withValues(alpha: 0.7 + pulse * 0.3);
      canvas.drawCircle(nodes[i], nodeRadius, nodePaint);
    }

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF42D4FF).withValues(alpha: 0.2);
    final orbitOffset = compact ? 2.0 : 6.0;
    canvas.drawCircle(center, radius + orbitOffset, orbitPaint);

    final signalAngle = progress * 2 * math.pi;
    final signalPos = Offset(
      center.dx + math.cos(signalAngle) * (radius + orbitOffset),
      center.dy + math.sin(signalAngle) * (radius + orbitOffset),
    );
    final signalPaint = Paint()
      ..color = const Color(0xFF59E390).withValues(alpha: 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, compact ? 1 : 2);
    canvas.drawCircle(signalPos, compact ? 1.5 : 2.5, signalPaint);
  }

  @override
  bool shouldRepaint(covariant _NeuralNetworkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
