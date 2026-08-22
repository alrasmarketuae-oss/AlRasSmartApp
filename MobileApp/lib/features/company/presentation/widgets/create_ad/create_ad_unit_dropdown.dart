import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_options.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdUnitDropdown extends StatelessWidget {
  const CreateAdUnitDropdown({
    super.key,
    required this.selectedUnit,
    required this.onChanged,
    this.isLocked = false,
    this.matchRowHeight = false,
  });

  final String selectedUnit;
  final ValueChanged<String> onChanged;
  final bool isLocked;
  final bool matchRowHeight;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final s = S.of(context);

    final fieldTextStyle = TextStyle(
      color: CreateAdDesign.text,
      fontFamily: fontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    final canonicalSelected = CreateAdUnitOptions.canonical(selectedUnit);
    final displayLabel = CreateAdUnitOptions.localizedLabel(canonicalSelected, s);

    if (isLocked) {
      final locked = InputDecorator(
        decoration: CreateAdFormFieldStyles.dropdownDecorator().copyWith(
          fillColor: const Color(0xFFF3F4F6),
        ),
        child: Text(
          displayLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fieldTextStyle,
        ),
      );
      if (matchRowHeight) {
        return CreateAdFormFieldStyles.buildRowDropdown(locked);
      }
      return locked;
    }

    final options = CreateAdUnitOptions.values.contains(canonicalSelected)
        ? CreateAdUnitOptions.values
        : <String>[canonicalSelected, ...CreateAdUnitOptions.values];

    final dropdown = _AnchoredUnitMenu(
      options: options,
      selectedUnit: canonicalSelected,
      displayLabel: displayLabel,
      fieldTextStyle: fieldTextStyle,
      onChanged: onChanged,
    );

    if (matchRowHeight) {
      return CreateAdFormFieldStyles.buildRowDropdown(dropdown);
    }

    return dropdown;
  }
}

/// Opens the unit list starting at the field, then scrolls downward.
class _AnchoredUnitMenu extends StatefulWidget {
  const _AnchoredUnitMenu({
    required this.options,
    required this.selectedUnit,
    required this.displayLabel,
    required this.fieldTextStyle,
    required this.onChanged,
  });

  final List<String> options;
  final String selectedUnit;
  final String displayLabel;
  final TextStyle fieldTextStyle;
  final ValueChanged<String> onChanged;

  @override
  State<_AnchoredUnitMenu> createState() => _AnchoredUnitMenuState();
}

class _AnchoredUnitMenuState extends State<_AnchoredUnitMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AnchoredUnitMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUnit != widget.selectedUnit) {
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

  Future<void> _toggle() async {
    if (_open) {
      _removeOverlay();
      return;
    }

    await Scrollable.ensureVisible(
      context,
      alignment: 0.18,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final fieldSize = box.size;
    final fieldOffset = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final screen = media.size;
    final spaceBelow =
        screen.height - fieldOffset.dy - fieldSize.height - media.padding.bottom - 12;
    final maxHeight = spaceBelow < 96 ? 96.0 : spaceBelow.clamp(96.0, 320.h);

    final menuWidth = fieldSize.width.clamp(160.w, screen.width - 32.w);
    final s = S.of(context);

    _entry = OverlayEntry(
      builder: (context) {
        final direction = Directionality.of(context);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: AlignmentDirectional.bottomEnd.resolve(direction),
              followerAnchor: AlignmentDirectional.topEnd.resolve(direction),
              offset: const Offset(0, 4),
              child: Material(
                color: CreateAdDesign.cardBg,
                elevation: 10,
                shadowColor: const Color(0xFF16233A).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10.r),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: fieldSize.width,
                    maxWidth: menuWidth,
                    maxHeight: maxHeight,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    shrinkWrap: true,
                    itemCount: widget.options.length,
                    itemBuilder: (context, index) {
                      final unit = widget.options[index];
                      final selected = unit == widget.selectedUnit;
                      return InkWell(
                        onTap: () {
                          _removeOverlay();
                          if (unit != widget.selectedUnit) {
                            widget.onChanged(unit);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          color: selected
                              ? const Color(0xFFE8F2FC)
                              : Colors.transparent,
                          child: Text(
                            CreateAdUnitOptions.localizedLabel(unit, s),
                            maxLines: 1,
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(10.r),
          child: InputDecorator(
            isEmpty: false,
            decoration: CreateAdFormFieldStyles.dropdownDecorator(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.fieldTextStyle,
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 22.sp,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
