import 'package:alrasmarket/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Overlays the sold-out stamp on product media so it reads like a seal on the photo.
class ProductSoldOutStampOverlay extends StatelessWidget {
  const ProductSoldOutStampOverlay({
    super.key,
    required this.child,
    this.visible = true,
    this.alignment = Alignment.center,
    this.rotationRadians = -0.12,
    this.sizeFactor = 0.75,
  });

  final Widget child;
  final bool visible;
  final Alignment alignment;
  final double rotationRadians;
  final double sizeFactor;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth.isFinite && constraints.maxHeight.isFinite
            ? constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight
            : 120.w;
        final stampSize = (side * sizeFactor).clamp(96.w, 228.w);

        return Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: alignment,
                  child: Transform.rotate(
                    angle: rotationRadians,
                    child: Image.asset(
                      AppAssets.soldOutStamp,
                      width: stampSize,
                      height: stampSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
