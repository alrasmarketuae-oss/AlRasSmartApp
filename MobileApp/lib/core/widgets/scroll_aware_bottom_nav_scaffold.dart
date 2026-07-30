import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Hides [bottomNavigationBar] when scrolling down and shows it when scrolling up.
class ScrollAwareBottomNavScaffold extends StatefulWidget {
  const ScrollAwareBottomNavScaffold({
    super.key,
    required this.body,
    required this.bottomNavigationBar,
    this.tabIndex = 0,
  });

  final Widget body;
  final Widget bottomNavigationBar;
  final int tabIndex;

  @override
  State<ScrollAwareBottomNavScaffold> createState() =>
      _ScrollAwareBottomNavScaffoldState();
}

class _ScrollAwareBottomNavScaffoldState
    extends State<ScrollAwareBottomNavScaffold> {
  bool _isBottomNavVisible = true;

  static const _scaffoldBg = Color(0xffF2F7FF);
  static const _statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // iOS: light background → dark (black) status icons.
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  void didUpdateWidget(covariant ScrollAwareBottomNavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex && !_isBottomNavVisible) {
      setState(() => _isBottomNavVisible = true);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification.metrics.pixels <= 0 && !_isBottomNavVisible) {
      setState(() => _isBottomNavVisible = true);
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.forward &&
          notification.metrics.pixels > 48 &&
          _isBottomNavVisible) {
        setState(() => _isBottomNavVisible = false);
      } else if (notification.direction == ScrollDirection.reverse &&
          !_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta == null || delta == 0) return false;

      if (delta > 0 && notification.metrics.pixels > 48 && _isBottomNavVisible) {
        setState(() => _isBottomNavVisible = false);
      } else if (delta < 0 && !_isBottomNavVisible) {
        setState(() => _isBottomNavVisible = true);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        body: SafeArea(
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: widget.body,
          ),
        ),
        bottomNavigationBar: ColoredBox(
          color: Colors.white,
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
