import 'package:flutter/material.dart';

/// Shows [label] with cycling trailing dots (`.` → `..` → `...`) while busy.
class AnimatedEllipsisText extends StatefulWidget {
  const AnimatedEllipsisText({
    super.key,
    required this.label,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String label;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  State<AnimatedEllipsisText> createState() => _AnimatedEllipsisTextState();
}

class _AnimatedEllipsisTextState extends State<AnimatedEllipsisText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.label.replaceFirst(RegExp(r'\.{1,3}\s*$'), '');
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = (_controller.value * 3).floor() % 3;
        final dots = '.' * (phase + 1);
        return Text(
          '$base$dots',
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          style: widget.style,
        );
      },
    );
  }
}
