import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Marker for fields / menus that must not dismiss the keyboard on tap.
///
/// Wrap text fields (and scrollable suggestion overlays) with:
/// `MetaData(metaData: kDismissKeyboardExempt, behavior: HitTestBehavior.deferToChild, child: …)`
const Object kDismissKeyboardExempt = Object();

/// Closes the software keyboard when the user taps outside the focused field.
///
/// Scrolls and drags do not dismiss. Works in release builds (does not rely on
/// [DebugCreator], which is null outside debug mode).
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

  // Tap landed on a text field, selector, exempt menu, or the focused box.
  if (_tapShouldKeepKeyboard(globalPosition, focus)) return;

  focus.unfocus();
}

bool _tapShouldKeepKeyboard(Offset globalPosition, FocusNode focus) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTest(result, globalPosition);

  var hasElevatedMenuSurface = false;
  var hasMenuListTile = false;
  var hasMenuInkWell = false;

  for (final entry in result.path) {
    final target = entry.target;

    // Explicit exempt wrappers (CustomTextFormField, search, dropdowns…).
    if (target is RenderMetaData &&
        identical(target.metaData, kDismissKeyboardExempt)) {
      return true;
    }

    // Release-safe: editable text render objects (no DebugCreator needed).
    if (target is RenderEditable) return true;

    if (target is! RenderObject) continue;

    // Debug / profile: widget-type checks when available.
    final creator = target.debugCreator;
    if (creator is DebugCreator) {
      final widget = creator.element.widget;
      if (_isTextInputWidget(widget)) return true;
      if (_isSelectorWidget(widget)) return true;
      if (widget is ListTile) hasMenuListTile = true;
      if (widget is InkWell) hasMenuInkWell = true;
      if (widget is Material && widget.elevation > 0) {
        hasElevatedMenuSurface = true;
      }
    }
  }

  // Autocomplete suggestions, custom country/port menus, and dropdown overlays.
  if (hasElevatedMenuSurface) return true;
  if (hasMenuListTile) return true;
  if (hasMenuInkWell && hasElevatedMenuSurface) return true;

  // Keep keyboard if tap is inside the focused field (or its decorator box).
  if (_tapInsideFocusedField(globalPosition, focus)) return true;

  return false;
}

bool _tapInsideFocusedField(Offset globalPosition, FocusNode focus) {
  RenderObject? current = focus.context?.findRenderObject();
  var depth = 0;
  while (current != null && depth < 8) {
    if (current is RenderBox && current.hasSize) {
      final origin = current.localToGlobal(Offset.zero);
      if ((origin & current.size).contains(globalPosition)) {
        return true;
      }
    }
    current = current.parent;
    depth++;
  }
  return false;
}

bool _isTextInputWidget(Widget widget) {
  if (widget is EditableText ||
      widget is TextField ||
      widget is TextFormField ||
      widget is InputDecorator) {
    return true;
  }
  final type = widget.runtimeType.toString();
  return type.contains('TextField') ||
      type.contains('TextForm') ||
      type.contains('CustomText') ||
      type.contains('AppSearch') ||
      type.contains('AppText');
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
