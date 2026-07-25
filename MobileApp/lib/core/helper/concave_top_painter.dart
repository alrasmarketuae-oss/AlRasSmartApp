import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConcaveTopPainter extends CustomPainter {
  final Color color;

  ConcaveTopPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    Path path = Path();

    // Starting point at top-left
    path.moveTo(0, 0);

    // Draw left side
    path.lineTo(0, size.height);

    // Draw bottom side
    path.lineTo(size.width, size.height);

    // Draw right side
    path.lineTo(size.width, 0);

    // Draw the concave curve at the top - this is the key difference
    // The curve dips down in the middle (concave)
    path.quadraticBezierTo(
      size.width / 2, // control point x (middle of width)
      100.h, // control point y (positive to create downward/concave curve)
      0, // end point x
      0, // end point y
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
