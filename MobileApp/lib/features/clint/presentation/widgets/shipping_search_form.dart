import 'package:alrasmarket/core/constants/country_names.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/shipping_filter_sheet.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_geo_dropdown_field.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShippingSearchForm extends StatefulWidget {
  const ShippingSearchForm({
    super.key,
    required this.initialFilters,
    required this.onFilter,
    this.isLoading = false,
  });

  final ShippingSearchFilters initialFilters;
  final ValueChanged<ShippingSearchFilters> onFilter;
  final bool isLoading;

  @override
  State<ShippingSearchForm> createState() => _ShippingSearchFormState();
}

class _ShippingSearchFormState extends State<ShippingSearchForm> {
  final GetGeoPortsByCountryUseCase _getGeoPortsByCountryUseCase =
      sl<GetGeoPortsByCountryUseCase>();

  final TextEditingController _fromCountryController = TextEditingController();
  final TextEditingController _toCountryController = TextEditingController();

  String? _fromPort;
  String? _toPort;
  String? _fromCountryResolved;
  String? _toCountryResolved;

  List<String> _fromPorts = const [];
  List<String> _toPorts = const [];
  bool _isLoadingFromPorts = false;
  bool _isLoadingToPorts = false;
  bool _isExpanded = false;

  final Map<String, ({String country, List<String> ports})> _portsCache = {};

  static const Color _labelColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _fromCountryController.text =
        widget.initialFilters.fromCountryName?.trim() ?? '';
    _toCountryController.text = widget.initialFilters.toCountryName?.trim() ?? '';
    _fromPort = widget.initialFilters.fromPortName;
    _toPort = widget.initialFilters.toPortName;
    _fromCountryResolved = _nullableTrim(_fromCountryController.text);
    _toCountryResolved = _nullableTrim(_toCountryController.text);

    if (_fromCountryController.text.isNotEmpty) {
      _fetchFromPorts(preselectPort: _fromPort);
    }
    if (_toCountryController.text.isNotEmpty) {
      _fetchToPorts(preselectPort: _toPort);
    }
  }

  @override
  void dispose() {
    _fromCountryController.dispose();
    _toCountryController.dispose();
    super.dispose();
  }

  String? _nullableTrim(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _fetchFromPorts({String? preselectPort}) async {
    final country = _fromCountryController.text.trim();
    if (country.isEmpty) return;

    setState(() {
      _fromPort = null;
      _fromPorts = const [];
      _isLoadingFromPorts = true;
    });
    await _loadPorts(
      country: country,
      isFrom: true,
      preselectPort: preselectPort,
    );
  }

  Future<void> _fetchToPorts({String? preselectPort}) async {
    final country = _toCountryController.text.trim();
    if (country.isEmpty) return;

    setState(() {
      _toPort = null;
      _toPorts = const [];
      _isLoadingToPorts = true;
    });
    await _loadPorts(
      country: country,
      isFrom: false,
      preselectPort: preselectPort,
    );
  }

  Future<void> _loadPorts({
    required String country,
    required bool isFrom,
    String? preselectPort,
  }) async {
    final cacheKey = country.trim().toLowerCase();
    if (_portsCache.containsKey(cacheKey)) {
      final cached = _portsCache[cacheKey]!;
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _fromCountryResolved = cached.country;
          _fromCountryController.text = cached.country;
          _fromPorts = cached.ports;
          _fromPort = _resolvePortSelection(cached.ports, preselectPort);
          _isLoadingFromPorts = false;
        } else {
          _toCountryResolved = cached.country;
          _toCountryController.text = cached.country;
          _toPorts = cached.ports;
          _toPort = _resolvePortSelection(cached.ports, preselectPort);
          _isLoadingToPorts = false;
        }
      });
      return;
    }

    final result = await _getGeoPortsByCountryUseCase(country);
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        if (isFrom) {
          _isLoadingFromPorts = false;
        } else {
          _isLoadingToPorts = false;
        }
      }),
      (response) {
        final portNames =
            response.ports.map((port) => port.displayName).toList();
        final normalizedCountry = response.country.isNotEmpty
            ? response.country
            : country;
        _portsCache[cacheKey] = (
          country: normalizedCountry,
          ports: portNames,
        );

        setState(() {
          if (isFrom) {
            if (_fromCountryController.text.trim().toLowerCase() == cacheKey) {
              _fromCountryController.text = normalizedCountry;
            }
            _fromCountryResolved = normalizedCountry;
            _fromPorts = portNames;
            _fromPort = _resolvePortSelection(portNames, preselectPort);
            _isLoadingFromPorts = false;
          } else {
            if (_toCountryController.text.trim().toLowerCase() == cacheKey) {
              _toCountryController.text = normalizedCountry;
            }
            _toCountryResolved = normalizedCountry;
            _toPorts = portNames;
            _toPort = _resolvePortSelection(portNames, preselectPort);
            _isLoadingToPorts = false;
          }
        });
      },
    );
  }

  String? _resolvePortSelection(List<String> ports, String? preferredPort) {
    final trimmed = preferredPort?.trim() ?? '';
    if (trimmed.isNotEmpty && ports.contains(trimmed)) {
      return trimmed;
    }
    return null;
  }

  void _applyFilter() {
    widget.onFilter(
      ShippingSearchFilters(
        fromCountryName:
            _fromCountryResolved ?? _nullableTrim(_fromCountryController.text),
        fromPortName: _fromPort,
        toCountryName:
            _toCountryResolved ?? _nullableTrim(_toCountryController.text),
        toPortName: _toPort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.filter,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: _labelColor,
                            fontFamily: fontFamily,
                          ),
                        ),
                        if (!_isExpanded && widget.initialFilters.hasAny) ...[
                          SizedBox(height: 4.h),
                          Text(
                            _filterSummary(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF667085),
                              fontFamily: fontFamily,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF3A7DC5),
                    size: 28.sp,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: Color(0xFFEAECF0)),
                  SizedBox(height: 16.h),
                  _buildLocationSection(
                    label: s.fromLabel,
                    countryController: _fromCountryController,
                    ports: _fromPorts,
                    selectedPort: _fromPort,
                    isPortsLoading: _isLoadingFromPorts,
                    fontFamily: fontFamily,
                    onCountrySearch: _fetchFromPorts,
                    onPortChanged: (value) => setState(() => _fromPort = value),
                  ),
                  SizedBox(height: 16.h),
                  _buildLocationSection(
                    label: s.toLabel,
                    countryController: _toCountryController,
                    ports: _toPorts,
                    selectedPort: _toPort,
                    isPortsLoading: _isLoadingToPorts,
                    fontFamily: fontFamily,
                    onCountrySearch: _fetchToPorts,
                    onPortChanged: (value) => setState(() => _toPort = value),
                  ),
                  SizedBox(height: 20.h),
                  PrimaryButton(
                    text: s.filter,
                    isLoading: widget.isLoading,
                    onPressed: () {
                      _applyFilter();
                      setState(() => _isExpanded = false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _filterSummary(BuildContext context) {
    final s = S.of(context);
    final parts = <String>[];

    if (widget.initialFilters.fromCountryName?.isNotEmpty ?? false) {
      parts.add('${s.fromLabel} ${widget.initialFilters.fromCountryName}');
    }
    if (widget.initialFilters.fromPortName?.isNotEmpty ?? false) {
      parts.add(widget.initialFilters.fromPortName!);
    }
    if (widget.initialFilters.toCountryName?.isNotEmpty ?? false) {
      parts.add('${s.toLabel} ${widget.initialFilters.toCountryName}');
    }
    if (widget.initialFilters.toPortName?.isNotEmpty ?? false) {
      parts.add(widget.initialFilters.toPortName!);
    }

    return parts.join(' • ');
  }

  Widget _buildLocationSection({
    required String label,
    required TextEditingController countryController,
    required List<String> ports,
    required String? selectedPort,
    required bool isPortsLoading,
    required String fontFamily,
    required VoidCallback onCountrySearch,
    required ValueChanged<String?> onPortChanged,
  }) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: _labelColor,
            fontFamily: fontFamily,
          ),
        ),
        SizedBox(height: 8.h),
        _CountrySearchField(
          controller: countryController,
          hintText: s.enterCountry,
          fontFamily: fontFamily,
          onSearch: onCountrySearch,
        ),
        SizedBox(height: 8.h),
        CreateAdGeoDropdownField(
          label: '',
          hint: s.enterPort,
          items: ports,
          selectedValue: selectedPort,
          isLoading: isPortsLoading,
          enabled: ports.isNotEmpty || isPortsLoading,
          onChanged: onPortChanged,
        ),
      ],
    );
  }
}

class _CountrySearchField extends StatefulWidget {
  const _CountrySearchField({
    required this.controller,
    required this.hintText,
    required this.fontFamily,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String hintText;
  final String fontFamily;
  final VoidCallback onSearch;

  @override
  State<_CountrySearchField> createState() => _CountrySearchFieldState();
}

class _CountrySearchFieldState extends State<_CountrySearchField> {
  @override
  Widget build(BuildContext context) {
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333).withValues(alpha: 0.8),
      fontFamily: widget.fontFamily,
      fontSize: 14.sp,
    );

    return Autocomplete<String>(
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }
        return AppCountryNames.all.where(
          (country) => country.toLowerCase().contains(query),
        );
      },
      onSelected: (selection) {
        widget.controller.text = selection;
        widget.onSearch();
      },
      displayStringForOption: (option) => option,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text.isEmpty &&
            widget.controller.text.isNotEmpty) {
          textEditingController.text = widget.controller.text;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: fieldTextStyle,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            if (widget.controller.text != value) {
              widget.controller.text = value;
            }
          },
          onFieldSubmitted: (_) {
            onFieldSubmitted();
            widget.onSearch();
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: fieldTextStyle.copyWith(
              color: AppColors.subtitle(context),
            ),
            filled: true,
            fillColor: AppColors.inputFill(context),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            suffixIcon: IconButton(
              icon: Icon(Icons.search_rounded, size: 22.sp),
              onPressed: widget.onSearch,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.border(context), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 220.h, maxWidth: 320.w),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontFamily: widget.fontFamily,
                        fontSize: 14.sp,
                        color: AppColors.title(context),
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
