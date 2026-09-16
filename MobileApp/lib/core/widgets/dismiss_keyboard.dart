import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Marker for scrollable suggestion / dropdown menus that must not dismiss
/// the keyboard (or close via unfocus) when the user scrolls them.
const Object kDismissKeyboardExempt = Object();

/// Closes the software keyboard when the user taps outside the focused field.
///
/// Scrolls and drags do not dismiss. Menus wrapped in
/// [MetaData] with [kDismissKeyboardExempt] are ignored.
class DismissKeyboard extends StatefulWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  State<DismissKeyboard> createState() => _DismissKeyboardState();
}

class _DismissKeyboardState extends State<DismissKeyboard> {
  int? _pointer;
  Offset? _downPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _downPosition = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _downPosition == null) return;
    if ((event.position - _downPosition!).distance > kTouchSlop) {
      _clearPointer();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final position = _downPosition;
    _clearPointer();
    if (position == null) return;
    // Real tap (not a scroll/drag): dismiss keyboard if outside the field/menu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dismissIfTapOutsideFocusedField(position);
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _clearPointer();
  }

  void _clearPointer() {
    _pointer = null;
    _downPosition = null;
  }
}

void _dismissIfTapOutsideFocusedField(Offset globalPosition) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return;

  if (_tapTargetsSelectorOrMenu(globalPosition)) return;

  final renderObject = focus.context?.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    final origin = renderObject.localToGlobal(Offset.zero);
    if ((origin & renderObject.size).contains(globalPosition)) {
      return;
    }
  }

  focus.unfocus();
}

bool _tapTargetsSelectorOrMenu(Offset globalPosition) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTest(result, globalPosition);

  var hasElevatedMenuSurface = false;
  var hasMenuListTile = false;
  var hasMenuInkWell = false;

  for (final entry in result.path) {
    final target = entry.target;

    if (target is RenderMetaData &&
        identical(target.metaData, kDismissKeyboardExempt)) {
      return true;
    }

    if (target is! RenderObject) continue;
    final creator = target.debugCreator;
    if (creator is! DebugCreator) continue;
    final widget = creator.element.widget;

    if (_isSelectorWidget(widget)) return true;

    if (widget is ListTile) hasMenuListTile = true;
    if (widget is InkWell) hasMenuInkWell = true;
    if (widget is Material && widget.elevation > 0) {
      hasElevatedMenuSurface = true;
    }
  }

  // Autocomplete suggestions, custom country/port menus, and dropdown overlays.
  if (hasElevatedMenuSurface) return true;
  if (hasMenuListTile) return true;
  if (hasMenuInkWell && hasElevatedMenuSurface) return true;

  return false;
}

bool _isSelectorWidget(Widget widget) {
  if (widget is DropdownButton ||
      widget is DropdownMenuItem ||
      widget is PopupMenuButton ||
      widget is PopupMenuItem ||
      widget is MenuItemButton ||
      widget is Radio ||
      widget is Checkbox ||
      widget is Switch ||
      widget is InputDecorator) {
    return true;
  }

  final type = widget.runtimeType.toString();
  return type.contains('Dropdown') ||
      type.contains('PopupMenu') ||
      type.contains('MenuItem') ||
      type.contains('Autocomplete') ||
      type.contains('Radio') ||
      type.contains('Checkbox') ||
      type.contains('Switch') ||
      type.contains('Chip');
}
