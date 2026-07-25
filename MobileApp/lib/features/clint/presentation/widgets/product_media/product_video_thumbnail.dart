import 'dart:io';

import 'package:alrasmarket/core/media/cached_video_controller.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_play_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class ProductVideoThumbnail extends StatefulWidget {
  const ProductVideoThumbnail({
    super.key,
    required this.videoUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.borderRadius,
    this.accentColor,
    this.showPlayChrome = true,
  });

  /// Remote http(s) URL, or a local device file path.
  final String videoUrl;
  final int? durationSeconds;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  /// Colored play triangle inside white circle (category accent).
  final Color? accentColor;
  final bool showPlayChrome;

  @override
  State<ProductVideoThumbnail> createState() => _ProductVideoThumbnailState();
}

class _ProductVideoThumbnailState extends State<ProductVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant ProductVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _failed = false;
      _initController();
    }
  }

  static bool _isLocalVideoPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return false;
    }
    if (trimmed.startsWith('file://')) return true;
    // Remote relative storage keys (e.g. /product-videos/x.mp4).
    if (trimmed.startsWith('/') &&
        !trimmed.startsWith('/data/') &&
        !trimmed.startsWith('/storage/') &&
        !trimmed.startsWith('/var/') &&
        !trimmed.startsWith('/private/') &&
        !trimmed.startsWith('/Users/') &&
        !trimmed.contains('/cache/') &&
        !trimmed.contains('/create_ad_assets/')) {
      return false;
    }
    return true;
  }

  Future<void> _initController() async {
    try {
      final source = widget.videoUrl.trim();
      if (source.isEmpty) {
        throw ArgumentError('Video URL is empty');
      }

      final VideoPlayerController controller;
      if (_isLocalVideoPath(source)) {
        final filePath = source.startsWith('file://')
            ? Uri.parse(source).toFilePath()
            : source;
        controller = VideoPlayerController.file(File(filePath));
      } else {
        controller = await createCachedNetworkVideoController(source);
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      await controller.seekTo(Duration.zero);
      controller.setVolume(0);
      controller.pause();
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  String _durationLabel() {
    final total =
        widget.durationSeconds ?? _controller?.value.duration.inSeconds ?? 0;
    if (total <= 0) return '';
    final minutes = total ~/ 60;
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.zero;
    final controller = _controller;
    final ready =
        controller != null && controller.value.isInitialized && !_failed;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              Container(
                color: const Color(0xFF1F2937),
                child: Center(
                  child: _failed
                      ? Icon(
                          Icons.videocam_off_outlined,
                          color: Colors.white54,
                          size: 28.sp,
                        )
                      : SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                ),
              ),
            Container(
              color: Colors.black.withValues(alpha: 0.18),
            ),
            if (widget.showPlayChrome)
              const Center(child: ProductVideoPlayMark()),
            if (_durationLabel().isNotEmpty)
              Positioned(
                left: 8.w,
                bottom: 8.h,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _durationLabel(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
