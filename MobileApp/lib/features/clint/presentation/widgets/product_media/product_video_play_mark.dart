import 'package:flutter/material.dart';

/// Shared video play mark: white play triangle only (no circle background).
class ProductVideoPlayMark extends StatelessWidget {
  const ProductVideoPlayMark({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final dim = size ?? 44;
    return Icon(
      Icons.play_arrow_rounded,
      color: Colors.white,
      size: dim * 0.9,
      shadows: const [
        Shadow(
          color: Color.fromRGBO(0, 0, 0, 0.45),
          blurRadius: 6,
          offset: Offset(0, 1),
        ),
      ],
    );
  }
}
