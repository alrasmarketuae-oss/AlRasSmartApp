import 'package:alrasmarket/core/utils/assets.dart';
import 'package:flutter/material.dart';

/// Full-bleed cold-start splash shown briefly after native splash dismisses.
class BrandSplashOverlay extends StatefulWidget {
  const BrandSplashOverlay({
    super.key,
    required this.child,
    this.visible = true,
    this.duration = const Duration(milliseconds: 2500),
  });

  final Widget child;
  final bool visible;
  final Duration duration;

  @override
  State<BrandSplashOverlay> createState() => _BrandSplashOverlayState();
}

class _BrandSplashOverlayState extends State<BrandSplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1,
    );
    if (!widget.visible) {
      _showSplash = false;
      return;
    }
    Future<void>.delayed(widget.duration, () async {
      if (!mounted) return;
      await _fade.reverse();
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: _fade,
          child: const ColoredBox(
            color: Colors.white,
            child: Image(
              image: AssetImage(AppAssets.splashScreen),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
  }
}
