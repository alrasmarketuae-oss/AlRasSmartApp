import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdGeoDropdownField extends StatelessWidget {
  const CreateAdGeoDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    this.isLoading = false,
    this.enabled = true,
    this.expandHeight = false,
    this.showLabel = true,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  final String label;
  final String hint;
  final List<String> items;
  final String? selectedValue;
  final String? Function(String?)? validator;
  final ValueChanged<String?> onChanged;
  final bool isLoading;
  final bool enabled;
  final bool expandHeight;
  final bool showLabel;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final fieldTextStyle = TextStyle(
      color: CreateAdDesign.text,
      fontFamily: fontFamily,
      fontSize: 14.sp,
    );
    final resolvedValue =
        items.contains(selectedValue) ? selectedValue : null;

    final menu = _AnchoredGeoMenu(
      hint: isLoading ? S.of(context).loadingEllipsis : hint,
      items: items,
      selectedValue: resolvedValue,
      fieldTextStyle: fieldTextStyle,
      isLoading: isLoading,
      enabled: enabled,
      fillColor: fillColor ?? CreateAdDesign.cardBg,
      borderColor: borderColor ?? CreateAdDesign.border,
      borderRadius: borderRadius ?? 8.r,
      validator: validator,
      onChanged: onChanged,
    );

    final field = expandHeight ? Expanded(child: menu) : menu;

    if (!showLabel || label.isEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}

class _AnchoredGeoMenu extends StatefulWidget {
  const _AnchoredGeoMenu({
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.fieldTextStyle,
    required this.isLoading,
    required this.enabled,
    required this.fillColor,
    required this.borderColor,
    required this.borderRadius,
    this.validator,
    required this.onChanged,
  });

  final String hint;
  final List<String> items;
  final String? selectedValue;
  final TextStyle fieldTextStyle;
  final bool isLoading;
  final bool enabled;
  final Color fillColor;
  final Color borderColor;
  final double borderRadius;
  final String? Function(String?)? validator;
  final ValueChanged<String?> onChanged;

  @override
  State<_AnchoredGeoMenu> createState() => _AnchoredGeoMenuState();
}

class _AnchoredGeoMenuState extends State<_AnchoredGeoMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  bool get _canOpen =>
      widget.enabled && !widget.isLoading && widget.items.isNotEmpty;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AnchoredGeoMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue ||
        oldWidget.items != widget.items) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    if (_open && mounted) {
      setState(() => _open = false);
    } else {
      _open = false;
    }
  }

  void _select(String value, FormFieldState<String> fieldState) {
    fieldState.didChange(value);
    _removeOverlay();
    if (value != widget.selectedValue) {
      widget.onChanged(value);
    }
  }

  Future<void> _toggle(FormFieldState<String> fieldState) async {
    if (!_canOpen) return;
    if (_open) {
      _removeOverlay();
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final fieldSize = box.size;
    final fieldOffset = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final spaceBelow = media.size.height -
        fieldOffset.dy -
        fieldSize.height -
        media.viewInsets.bottom -
        16;
    final maxHeight = spaceBelow < 96 ? 96.0 : spaceBelow.clamp(96.0, 320.h);

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(0, fieldSize.height + 4),
              child: Material(
                elevation: 8,
                color: widget.fillColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: fieldSize.width,
                    maxWidth: fieldSize.width,
                    maxHeight: maxHeight,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final selected = item == widget.selectedValue;
                      return InkWell(
                        onTapDown: (_) => _select(item, fieldState),
                        onTap: () => _select(item, fieldState),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          color: selected
                              ? const Color(0xFFE8F2FC)
                              : Colors.transparent,
                          child: Text(
                            item,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: widget.fieldTextStyle.copyWith(
                              color: selected
                                  ? const Color(0xFF1B5FB8)
                                  : CreateAdDesign.text,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    setState(() => _open = true);
  }

  InputDecoration _decoration({String? errorText}) {
    return InputDecoration(
      filled: true,
      fillColor: widget.fillColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: widget.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      errorText: errorText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.selectedValue ?? widget.hint;
    final isPlaceholder = widget.selectedValue == null;

    return FormField<String>(
      initialValue: widget.selectedValue,
      validator: widget.validator,
      builder: (fieldState) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canOpen ? () => _toggle(fieldState) : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InputDecorator(
                isEmpty: widget.selectedValue == null,
                decoration: _decoration(errorText: fieldState.errorText),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: widget.fieldTextStyle.copyWith(
                          color: isPlaceholder
                              ? const Color(0xFF333333).withValues(alpha: 0.4)
                              : widget.fieldTextStyle.color,
                          fontWeight: isPlaceholder
                              ? FontWeight.w500
                              : widget.fieldTextStyle.fontWeight,
                        ),
                      ),
                    ),
                    if (widget.isLoading)
                      SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _open
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF6B7280),
                        size: 20.sp,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
