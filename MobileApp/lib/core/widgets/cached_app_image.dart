import 'package:alrasmarket/core/media/app_media_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Network image with disk + memory cache (CDN URLs).
///
/// Loading uses a skeleton shimmer (never a spinner). Already-cached images
/// paint immediately; call [precacheUrls] to warm neighbors ahead of swipe.
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
    this.darkSkeleton = false,
    this.fadeInDuration = const Duration(milliseconds: 120),
  });

  final String? imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Use darker shimmer for fullscreen / dark media viewers.
  final bool darkSkeleton;

  /// Keep short; zero feels abrupt when decoding from disk.
  final Duration fadeInDuration;

  static const _imageHeaders = <String, String>{
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 '
        'AlRasMarket/1.0',
  };

  /// Warm disk + memory cache for upcoming carousel / gallery slides.
  static Future<void> precacheUrls(
    BuildContext context,
    Iterable<String?> urls, {
    int maxConcurrent = 3,
  }) async {
    final unique = <String>{};
    for (final raw in urls) {
      final url = raw?.trim();
      if (url == null || url.isEmpty) continue;
      if (url.startsWith('file:') || url.startsWith('/data/')) continue;
      if (!(url.startsWith('http://') || url.startsWith('https://'))) continue;
      unique.add(url);
    }
    if (unique.isEmpty || !context.mounted) return;

    final pending = unique.toList();
    var index = 0;

    Future<void> worker() async {
      while (true) {
        if (index >= pending.length) return;
        final i = index++;
        final url = pending[i];
        try {
          await AppMediaCacheManager.instance.downloadFile(
            url,
            authHeaders: _imageHeaders,
          );
          if (!context.mounted) return;
          await precacheImage(
            CachedNetworkImageProvider(
              url,
              cacheManager: AppMediaCacheManager.instance,
              headers: _imageHeaders,
            ),
            context,
          );
        } catch (_) {
          // Best-effort preload; failures are ignored.
        }
      }
    }

    final workers = List.generate(
      maxConcurrent.clamp(1, pending.length),
      (_) => worker(),
    );
    await Future.wait(workers);
  }

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
      fadeInDuration: fadeInDuration,
      fadeOutDuration: Duration.zero,
      memCacheWidth:
          width != null && width!.isFinite ? (width! * 3).round() : null,
      placeholder: (_, __) =>
          placeholder ?? _defaultPlaceholder(dark: darkSkeleton),
      errorWidget: (_, __, ___) => errorWidget ?? _defaultError(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _defaultPlaceholder({required bool dark}) {
    final base = dark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final highlight = dark ? const Color(0xFF4B5563) : const Color(0xFFF9FAFB);
    final fill = dark ? const Color(0xFF1F2937) : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        color: fill,
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
