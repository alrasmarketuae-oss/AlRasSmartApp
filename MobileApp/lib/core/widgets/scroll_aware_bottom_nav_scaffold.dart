import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.body,
      ),
      bottomNavigationBar: ClipRect(
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          heightFactor: _isBottomNavVisible ? 1 : 0,
          child: widget.bottomNavigationBar,
        ),
      ),
    );
  }
}
