import 'dart:async';

import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Hides [bottomNavigationBar] when scrolling down and shows it when scrolling up
/// or when scrolling stops.
class ScrollAwareBottomNavScaffold extends StatefulWidget {
  const ScrollAwareBottomNavScaffold({
    super.key,
    required this.body,
    required this.bottomNavigationBar,
    this.tabIndex = 0,
    this.backgroundColor,
  });

  final Widget body;
  final Widget bottomNavigationBar;
  final int tabIndex;
  /// Background of the active tab; also fills the status bar area above it.
  final Color? backgroundColor;

  @override
  State<ScrollAwareBottomNavScaffold> createState() =>
      _ScrollAwareBottomNavScaffoldState();
}

class _ScrollAwareBottomNavScaffoldState
    extends State<ScrollAwareBottomNavScaffold> {
  bool _isBottomNavVisible = true;
  bool _ignoreLayoutScroll = false;
  Timer? _ignoreTimer;

  @override
  void dispose() {
    _ignoreTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScrollAwareBottomNavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex && !_isBottomNavVisible) {
      _setVisible(true);
    }
  }

  void _setVisible(bool visible) {
    if (_isBottomNavVisible == visible) return;
    setState(() => _isBottomNavVisible = visible);
    _ignoreLayoutScroll = true;
    _ignoreTimer?.cancel();
    _ignoreTimer = Timer(const Duration(milliseconds: 320), () {
      _ignoreLayoutScroll = false;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (_ignoreLayoutScroll) return false;

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      if (!_isBottomNavVisible) {
        _setVisible(true);
      }
      return false;
    }

    if (notification is! ScrollUpdateNotification) return false;

    final delta = notification.scrollDelta;
    if (delta == null || delta.abs() < 2) return false;

    if (notification.metrics.pixels <= 8) {
      _setVisible(true);
      return false;
    }

    if (delta > 2) {
      _setVisible(false);
    } else if (delta < -2) {
      _setVisible(true);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.backgroundColor ?? AppColors.scaffold(context);
    final useLightIcons =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark;
    final navColor = AppColors.navBar(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: background,
        statusBarBrightness:
            useLightIcons ? Brightness.dark : Brightness.light,
        statusBarIconBrightness:
            useLightIcons ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: navColor,
        systemNavigationBarIconBrightness:
            useLightIcons ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: background,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: widget.body,
          ),
        ),
        bottomNavigationBar: ColoredBox(
          color: navColor,
          child: SafeArea(
            top: false,
            child: ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                heightFactor: _isBottomNavVisible ? 1 : 0,
                child: widget.bottomNavigationBar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
