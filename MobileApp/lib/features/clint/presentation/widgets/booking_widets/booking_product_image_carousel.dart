import 'package:alrasmarket/core/media/cached_video_controller.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/clint/presentation/models/product_media_item.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_preview_screen.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_play_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class BookingProductImageCarousel extends StatefulWidget {
  const BookingProductImageCarousel({
    super.key,
    required this.mediaItems,
  });

  final List<ProductMediaItem> mediaItems;

  @override
  State<BookingProductImageCarousel> createState() =>
      _BookingProductImageCarouselState();
}

class _BookingProductImageCarouselState
    extends State<BookingProductImageCarousel> {
  int _currentIndex = 0;

  bool get _onlyVideo =>
      widget.mediaItems.length == 1 && widget.mediaItems.first.isVideo;

  @override
  Widget build(BuildContext context) {
    final count =
        widget.mediaItems.isEmpty ? 1 : widget.mediaItems.length;

    return ClipRRect(
      child: Stack(
        children: [
          SizedBox(
            height: 188.h,
            width: double.infinity,
            child: widget.mediaItems.isEmpty
                ? Image.asset(AppAssets.bannerImage2, fit: BoxFit.cover)
                : PageView.builder(
                    itemCount: widget.mediaItems.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (_, index) {
                      final item = widget.mediaItems[index];
                      return GestureDetector(
                        onTap: () => ProductMediaPreviewScreen.open(
                          context,
                          items: widget.mediaItems,
                          initialIndex: index,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: _MediaSlide(
                          item: item,
                          autoPlay: _onlyVideo && index == 0,
                        ),
                      );
                    },
                  ),
          ),
          if (widget.mediaItems.length > 1)
            Positioned(
              bottom: 12.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  count,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: index == _currentIndex ? 16.w : 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? const Color(0xFF3A7DC5)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaSlide extends StatefulWidget {
  const _MediaSlide({
    required this.item,
    required this.autoPlay,
  });

  final ProductMediaItem item;
  final bool autoPlay;

  @override
  State<_MediaSlide> createState() => _MediaSlideState();
}

class _MediaSlideState extends State<_MediaSlide> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo && widget.autoPlay) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _MediaSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.url != widget.item.url ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.item.isMuted != widget.item.isMuted) {
      _disposeVideo();
      _failed = false;
      if (widget.item.isVideo && widget.autoPlay) {
        _initVideo();
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _initVideo() async {
    final controller = await createCachedNetworkVideoController(widget.item.url);
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(widget.item.isMuted ? 0 : 1);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.isVideo) {
      return CachedAppImage(
        imageUrl: widget.item.url,
        fit: BoxFit.cover,
        errorWidget: Image.asset(AppAssets.bannerImage2, fit: BoxFit.cover),
      );
    }

    final controller = _controller;
    final ready =
        widget.autoPlay &&
        controller != null &&
        controller.value.isInitialized &&
        !_failed;

    if (ready) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF1F2937)),
        Center(
          child: ProductVideoPlayMark(size: 56.sp),
        ),
      ],
    );
  }
}
