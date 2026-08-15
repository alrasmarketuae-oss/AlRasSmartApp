import 'package:flutter/material.dart';

/// Closes the software keyboard when the user taps anywhere except the
/// currently focused text field.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _dismissIfTapOutsideFocusedField,
      child: child,
    );
  }
}

void _dismissIfTapOutsideFocusedField(PointerDownEvent event) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return;

  final renderObject = focus.context?.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    final origin = renderObject.localToGlobal(Offset.zero);
    if ((origin & renderObject.size).contains(event.position)) {
      return;
    }
  }

  focus.unfocus();
}
