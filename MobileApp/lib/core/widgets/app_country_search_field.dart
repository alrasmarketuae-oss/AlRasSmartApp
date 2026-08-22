import 'package:alrasmarket/core/constants/country_names.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppCountrySearchField extends StatefulWidget {
  const AppCountrySearchField({
    super.key,
    this.value,
    required this.onChanged,
    this.hintText,
    this.validator,
    this.fontFamily,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hintText;
  final String? Function(String?)? validator;
  final String? fontFamily;
  final bool enabled;

  @override
  State<AppCountrySearchField> createState() => _AppCountrySearchFieldState();
}

class _AppCountrySearchFieldState extends State<AppCountrySearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filtered = AppCountryNames.all.take(12).toList();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AppCountrySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value ?? '';
    if (nextValue != _controller.text) {
      _controller.text = nextValue;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!widget.enabled) return;
    if (_focusNode.hasFocus) {
      _filterOptions(_controller.text);
      return;
    }
    // Let suggestion taps finish before closing the overlay.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _focusNode.hasFocus) return;
      _removeOverlay();
    });
  }

  void _filterOptions(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) {
      _filtered = AppCountryNames.all.take(12).toList();
      return;
    }
    _filtered = AppCountryNames.all
        .where((country) => _matchesCountryQuery(country, query))
        .take(24)
        .toList();
  }

  void _applySelection(String country, FormFieldState<String> fieldState) {
    if (!widget.enabled) return;
    _controller.text = country;
    fieldState.didChange(country);
    widget.onChanged(country);
    _removeOverlay();
    _focusNode.unfocus();
    if (mounted) setState(() {});
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(FormFieldState<String> fieldState) {
    if (!widget.enabled || !mounted) return;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) {
          return const SizedBox.shrink();
        }

        final fieldSize = box.size;
        final fieldOffset = box.localToGlobal(Offset.zero);
        final media = MediaQuery.of(overlayContext);
        final spaceBelow = media.size.height -
            fieldOffset.dy -
            fieldSize.height -
            media.viewInsets.bottom -
            16;
        final maxHeight = spaceBelow < 96 ? 96.0 : spaceBelow.clamp(96.0, 260.h);

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
                borderRadius: BorderRadius.circular(8.r),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: fieldSize.width,
                    maxWidth: fieldSize.width,
                    maxHeight: maxHeight,
                  ),
                  child: _filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Text(
                            S.of(overlayContext).selectAnOption,
                            style: TextStyle(
                              fontFamily: widget.fontFamily ??
                                  AppFonts.familyFor(
                                    Localizations.localeOf(overlayContext),
                                  ),
                              fontSize: 13.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final option = _filtered[index];
                            final selected =
                                option.toLowerCase() ==
                                    _controller.text.trim().toLowerCase();
                            return InkWell(
                              onTapDown: (_) =>
                                  _applySelection(option, fieldState),
                              onTap: () =>
                                  _applySelection(option, fieldState),
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
                                  option,
                                  style: TextStyle(
                                    fontFamily: widget.fontFamily ??
                                        AppFonts.familyFor(
                                          Localizations.localeOf(context),
                                        ),
                                    fontSize: 14.sp,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? const Color(0xFF1B5FB8)
                                        : const Color(0xFF333333),
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

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        widget.fontFamily ?? AppFonts.familyFor(Localizations.localeOf(context));
    final hintText = widget.hintText ?? S.of(context).enterCountry;
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333).withValues(alpha: 0.8),
      fontFamily: fontFamily,
      fontSize: 14.sp,
    );

    return FormField<String>(
      initialValue: widget.value,
      validator: (value) {
        final trimmed = (value ?? _controller.text).trim();
        if (widget.enabled && trimmed.isNotEmpty) {
          final match = AppCountryNames.all.firstWhere(
            (country) => country.toLowerCase() == trimmed.toLowerCase(),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            widget.onChanged(match);
          }
        }
        return widget.validator?.call(trimmed.isEmpty ? null : trimmed);
      },
      builder: (fieldState) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            style: fieldTextStyle,
            textInputAction: TextInputAction.search,
            onTap: () {
              if (!widget.enabled) return;
              _filterOptions(_controller.text);
              _showOverlay(fieldState);
            },
            onChanged: (value) {
              final trimmed = value.trim();
              fieldState.didChange(trimmed.isEmpty ? null : trimmed);
              if (!widget.enabled) return;
              _filterOptions(value);
              _showOverlay(fieldState);
              if (trimmed.isEmpty) {
                widget.onChanged(null);
                return;
              }
              final match = AppCountryNames.all.firstWhere(
                (country) => country.toLowerCase() == trimmed.toLowerCase(),
                orElse: () => '',
              );
              if (match.isNotEmpty) {
                widget.onChanged(match);
              }
            },
            onFieldSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isEmpty || !widget.enabled) return;
              final match = AppCountryNames.all.firstWhere(
                (country) => country.toLowerCase() == trimmed.toLowerCase(),
                orElse: () => trimmed,
              );
              if (AppCountryNames.all.contains(match)) {
                _applySelection(match, fieldState);
              }
            },
            onTapOutside: (_) {},
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: fieldTextStyle.copyWith(
                color: const Color(0xFF333333).withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 14.h,
              ),
              suffixIcon: Icon(
                Icons.search_rounded,
                size: 22.sp,
                color: const Color(0xFF6B7280),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              errorText: fieldState.errorText,
            ),
          ),
        );
      },
    );
  }
}

bool _matchesCountryQuery(String country, String query) {
  final normalizedCountry = country.toLowerCase();
  if (normalizedCountry.contains(query)) return true;

  final countryTokens = normalizedCountry.split(RegExp(r'[\s,]+'));
  for (final token in countryTokens) {
    if (token.startsWith(query) || query.startsWith(token)) {
      return true;
    }
  }

  if (query.length >= 3) {
    final prefix = query.substring(0, query.length - 1);
    if (normalizedCountry.contains(prefix)) return true;
  }

  return false;
}
