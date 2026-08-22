import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Closes the software keyboard when the user taps outside the focused field.
///
/// Unfocus is deferred to the next frame so dropdowns and selectors receive
/// the tap before the keyboard closes (immediate unfocus cancels selection).
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _scheduleDismissIfTapOutsideFocusedField,
      child: child,
    );
  }
}

void _scheduleDismissIfTapOutsideFocusedField(PointerDownEvent event) {
  final position = event.position;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _dismissIfTapOutsideFocusedField(position);
  });
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
    if (target is! RenderObject) continue;
    final creator = target.debugCreator;
    if (creator is! Widget) continue;
    final widget = creator;

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
