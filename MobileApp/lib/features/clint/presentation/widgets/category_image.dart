import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class CategoryImage extends StatelessWidget {
  const CategoryImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final Widget child;
    if (url == null || url.isEmpty) {
      child = Icon(
        Icons.category_outlined,
        size: 28.sp,
        color: const Color(0xFF6B7280),
      );
    } else {
      child = CachedAppImage(
        imageUrl: url,
        fit: fit,
        borderRadius: borderRadius,
        placeholder: _imagePlaceholder(),
        errorWidget: Icon(
          Icons.category_outlined,
          size: 28.sp,
          color: const Color(0xFF6B7280),
        ),
      );
    }

    if (borderRadius != null && url != null && url.isNotEmpty) {
      return child;
    }
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _imagePlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      child: Container(color: Colors.white),
    );
  }
}
