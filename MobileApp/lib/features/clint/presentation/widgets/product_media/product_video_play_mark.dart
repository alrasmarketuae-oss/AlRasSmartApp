import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared video play mark: translucent circle + solid white triangle.
class ProductVideoPlayMark extends StatelessWidget {
  const ProductVideoPlayMark({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final dim = size ?? 44.w;
    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.16),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: dim * 0.68,
      ),
    );
  }
}
