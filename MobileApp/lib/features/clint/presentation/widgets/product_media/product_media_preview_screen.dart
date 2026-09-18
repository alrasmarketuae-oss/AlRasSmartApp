import 'dart:io';

import 'package:alrasmarket/core/media/cached_video_controller.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/clint/presentation/models/product_media_item.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_play_mark.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class ProductMediaPreviewScreen extends StatefulWidget {
  const ProductMediaPreviewScreen({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<ProductMediaItem> items;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<ProductMediaItem> items,
    int initialIndex = 0,
  }) {
    if (items.isEmpty) return Future.value();
    final safeIndex = initialIndex.clamp(0, items.length - 1);
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ProductMediaPreviewScreen(
          items: items,
          initialIndex: safeIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ProductMediaPreviewScreen> createState() =>
      _ProductMediaPreviewScreenState();
}

class _ProductMediaPreviewScreenState extends State<ProductMediaPreviewScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  bool _videoFailed = false;
  double _dragOffsetY = 0;
  double _dismissOpacity = 1;
  int _videoInitGeneration = 0;

  bool get _canLoop => widget.items.length > 1;

  /// Three virtual copies; stay in the middle so swipe can wrap safely.
  static const int _loopCopies = 3;

  int get _itemCount => widget.items.length;

  int _realIndex(int page) {
    final count = _itemCount;
    if (count <= 0) return 0;
    return ((page % count) + count) % count;
  }

  int _pageForRealIndex(int realIndex) {
    if (!_canLoop) return realIndex;
    return _itemCount + realIndex;
  }

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.items.isEmpty ? 0 : widget.items.length - 1;
    _currentIndex =
        widget.items.isEmpty ? 0 : widget.initialIndex.clamp(0, maxIndex);
    _pageController =
        PageController(initialPage: _pageForRealIndex(_currentIndex));
    if (widget.items.isNotEmpty) {
      _initVideoForIndex(_currentIndex);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.items.isEmpty) return;
      _precacheAround(_currentIndex, includeAll: true);
    });
  }

  void _precacheAround(int index, {bool includeAll = false}) {
    final urls = <String?>[];
    if (includeAll) {
      for (final item in widget.items) {
        if (!item.isVideo) urls.add(item.url);
      }
    } else {
      final count = widget.items.length;
      if (count == 0) return;
      for (final i in [index - 1, index, index + 1]) {
        final wrapped = ((i % count) + count) % count;
        final item = widget.items[wrapped];
        if (!item.isVideo) urls.add(item.url);
      }
    }
    CachedAppImage.precacheUrls(context, urls);
  }

  @override
  void dispose() {
    _videoInitGeneration++;
    _disposeVideoController();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initVideoForIndex(int index) async {
    final generation = ++_videoInitGeneration;
    _disposeVideoController();

    if (index < 0 || index >= widget.items.length) return;
    final item = widget.items[index];
    if (!item.isVideo) {
      if (mounted && generation == _videoInitGeneration) {
        setState(() {
          _isVideoInitializing = false;
          _videoFailed = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isVideoInitializing = true;
        _videoFailed = false;
      });
    }

    final controller = await _createVideoController(item.url);
    if (!mounted || generation != _videoInitGeneration) {
      await controller.dispose();
      return;
    }
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted || generation != _videoInitGeneration) {
        await controller.dispose();
        if (_videoController == controller) _videoController = null;
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(item.isMuted ? 0 : 1);
      await controller.play();
    } catch (_) {
      if (mounted && generation == _videoInitGeneration) {
        setState(() {
          _isVideoInitializing = false;
          _videoFailed = true;
        });
      }
      await controller.dispose();
      if (_videoController == controller) {
        _videoController = null;
      }
      return;
    }

    if (!mounted || generation != _videoInitGeneration) {
      await controller.dispose();
      if (_videoController == controller) _videoController = null;
      return;
    }

    setState(() => _isVideoInitializing = false);
  }

  Future<VideoPlayerController> _createVideoController(String source) async {
    if (_isLocalPath(source)) {
      return VideoPlayerController.file(File(source));
    }
    return createCachedNetworkVideoController(source);
  }

  static bool _isLocalPath(String source) {
    final value = source.trim();
    if (value.isEmpty) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }
    return true;
  }

  void _disposeVideoController() {
    final controller = _videoController;
    _videoController = null;
    controller?.dispose();
  }

  bool get _shouldShowVideoSeekBar {
    if (_isVideoInitializing || _videoFailed) return false;
    if (_currentIndex < 0 || _currentIndex >= widget.items.length) return false;
    final item = widget.items[_currentIndex];
    final controller = _videoController;
    return item.isVideo &&
        controller != null &&
        controller.value.isInitialized;
  }

  void _onPageChanged(int page) {
    final index = _realIndex(page);
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _videoFailed = false;
      });
      _initVideoForIndex(index);
      _precacheAround(index);
    }

    if (!_canLoop) return;
    final count = _itemCount;
    // Keep the viewport in the middle copy so the next swipe can wrap again.
    if (page < count || page >= count * (_loopCopies - 1)) {
      final target = count + index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        if (_pageController.page?.round() == target) return;
        _pageController.jumpToPage(target);
      });
    }
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    if (mounted) setState(() {});
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _goToPrevious() {
    if (!_canLoop || !_pageController.hasClients) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNext() {
    if (!_canLoop || !_pageController.hasClients) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;
    if (dy == 0) return;
    setState(() {
      _dragOffsetY = (_dragOffsetY + dy).clamp(0, 400);
      _dismissOpacity = (1 - (_dragOffsetY / 280)).clamp(0.35, 1);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffsetY > 120 || velocity > 900) {
      _close();
      return;
    }
    setState(() {
      _dragOffsetY = 0;
      _dismissOpacity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: _CloseMediaButton(onPressed: _close),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _dismissOpacity),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffsetY),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Directionality(
                // Product order and navigation controls must stay physical:
                // left = previous, right = next, even when the app is Arabic.
                textDirection: TextDirection.ltr,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _canLoop ? _itemCount * _loopCopies : _itemCount,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, page) {
                    final index = _realIndex(page);
                    final item = widget.items[index];
                    if (item.isVideo) {
                      return _VideoPreviewBody(
                        key: ValueKey('video-$index-${item.url}'),
                        controller:
                            index == _currentIndex ? _videoController : null,
                        isInitializing:
                            index == _currentIndex && _isVideoInitializing,
                        failed: index == _currentIndex && _videoFailed,
                        onRetry: index == _currentIndex
                            ? () => _initVideoForIndex(index)
                            : null,
                        onTogglePlayPause: _togglePlayPause,
                      );
                    }

                    return _SwipeFriendlyZoomImage(
                      key: ValueKey('img-$index-${item.url}'),
                      child: _isLocalPath(item.url)
                          ? Image.file(
                              File(item.url),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            )
                          : CachedAppImage(
                              imageUrl: item.url,
                              fit: BoxFit.contain,
                              darkSkeleton: true,
                              fadeInDuration: Duration.zero,
                              // Avoid broken-image flash over ads media.
                              errorWidget: const SizedBox.shrink(),
                            ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Always visual top-left (ignore RTL so close stays left).
                    Positioned(
                      top: 4.h,
                      left: 8.w,
                      child: _CloseMediaButton(onPressed: _close),
                    ),
                    if (widget.items.length > 1)
                      Positioned(
                        top: 4.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.items.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (widget.items.length > 1) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: _NavMediaButton(
                            icon: Icons.chevron_left_rounded,
                            enabled: widget.items.length > 1,
                            onPressed: _goToPrevious,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _NavMediaButton(
                            icon: Icons.chevron_right_rounded,
                            enabled: widget.items.length > 1,
                            onPressed: _goToNext,
                          ),
                        ),
                      ),
                    ],
                    if (_shouldShowVideoSeekBar)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _VideoSeekBar(controller: _videoController!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeFriendlyZoomImage extends StatefulWidget {
  const _SwipeFriendlyZoomImage({super.key, required this.child});

  final Widget child;

  @override
  State<_SwipeFriendlyZoomImage> createState() =>
      _SwipeFriendlyZoomImageState();
}

class _SwipeFriendlyZoomImageState extends State<_SwipeFriendlyZoomImage> {
  final _transform = TransformationController();
  bool _panEnabled = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _syncPanEnabled() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.05;
    if (zoomed == _panEnabled) return;
    setState(() => _panEnabled = zoomed);
  }

  @override
  Widget build(BuildContext context) {
    // When not zoomed, disable pan so PageView receives horizontal swipes
    // (including wrap from last → first / first → last).
    return InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 4,
      panEnabled: _panEnabled,
      scaleEnabled: true,
      onInteractionUpdate: (_) => _syncPanEnabled(),
      onInteractionEnd: (_) {
        // Reset tiny residual zoom so swipe keeps working.
        if (_transform.value.getMaxScaleOnAxis() <= 1.05) {
          _transform.value = Matrix4.identity();
          if (_panEnabled) setState(() => _panEnabled = false);
        } else {
          _syncPanEnabled();
        }
      },
      child: Center(child: widget.child),
    );
  }
}

class _VideoSeekBar extends StatelessWidget {
  const _VideoSeekBar({required this.controller});

  final VideoPlayerController controller;

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.72),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 18.h, 12.w, 8.h),
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final maxMs = value.duration.inMilliseconds;
              final posMs = value.position.inMilliseconds
                  .clamp(0, maxMs < 1 ? 0 : maxMs);
              final canSeek = maxMs > 0;

              return Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Text(
                      _formatDuration(value.position),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.h,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 7.r,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 14.r,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.28),
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: Slider(
                          min: 0,
                          max: canSeek ? maxMs.toDouble() : 1,
                          value: canSeek ? posMs.toDouble() : 0,
                          onChanged: canSeek
                              ? (v) => controller.seekTo(
                                    Duration(milliseconds: v.round()),
                                  )
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(value.duration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CloseMediaButton extends StatelessWidget {
  const _CloseMediaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: 28.w, height: 28.w),
      icon: Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 22.sp,
        shadows: const [
          Shadow(
            color: Color.fromRGBO(0, 0, 0, 0.55),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _NavMediaButton extends StatelessWidget {
  const _NavMediaButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: 48.w, height: 48.w),
      icon: Icon(
        icon,
        // Do not mirror chevrons with the Arabic Directionality.
        textDirection: TextDirection.ltr,
        color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
        size: 36.sp,
        shadows: const [
          Shadow(
            color: Color.fromRGBO(0, 0, 0, 0.7),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _VideoPreviewBody extends StatefulWidget {
  const _VideoPreviewBody({
    super.key,
    required this.controller,
    required this.isInitializing,
    required this.failed,
    this.onRetry,
    this.onTogglePlayPause,
  });

  final VideoPlayerController? controller;
  final bool isInitializing;
  final bool failed;
  final VoidCallback? onRetry;
  final VoidCallback? onTogglePlayPause;

  @override
  State<_VideoPreviewBody> createState() => _VideoPreviewBodyState();
}

class _VideoPreviewBodyState extends State<_VideoPreviewBody> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onVideoUpdate);
  }

  @override
  void didUpdateWidget(covariant _VideoPreviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onVideoUpdate);
      widget.controller?.addListener(_onVideoUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (widget.failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onRetry != null)
              TextButton(
                onPressed: widget.onRetry,
                child: Text(
                  s.retry,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      );
    }

    if (widget.isInitializing ||
        widget.controller == null ||
        !widget.controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final video = widget.controller!;
    final isPlaying = video.value.isPlaying;

    return GestureDetector(
      onTap: widget.onTogglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: video.value.size.width > 0 ? video.value.size.width : 320,
                height:
                    video.value.size.height > 0 ? video.value.size.height : 240,
                child: VideoPlayer(video),
              ),
            ),
          ),
          if (!isPlaying) ProductVideoPlayMark(size: 64.sp),
        ],
      ),
    );
  }
}
