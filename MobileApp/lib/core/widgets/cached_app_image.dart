import 'package:alrasmarket/core/media/app_media_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Network image with disk + memory cache (CDN URLs).
class CachedAppImage extends StatelessWidget {
  const CachedAppImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  static const _imageHeaders = <String, String>{
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 '
        'AlRasMarket/1.0',
  };

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return errorWidget ?? const SizedBox.shrink();
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppMediaCacheManager.instance,
      httpHeaders: _imageHeaders,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth:
          width != null && width!.isFinite ? (width! * 3).round() : null,
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (_, __, ___) => errorWidget ?? _defaultError(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _defaultPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: const Color(0xFF9CA3AF),
        size: (height ?? 48) * 0.4,
      ),
    );
  }
}
