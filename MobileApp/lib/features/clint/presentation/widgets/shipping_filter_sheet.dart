import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/company/data/models/geo_response_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShippingSearchFilters {
  const ShippingSearchFilters({
    this.fromCountryName,
    this.fromPortName,
    this.toCountryName,
    this.toPortName,
  });

  final String? fromCountryName;
  final String? fromPortName;
  final String? toCountryName;
  final String? toPortName;

  bool get hasAny =>
      (fromCountryName?.isNotEmpty ?? false) ||
      (fromPortName?.isNotEmpty ?? false) ||
      (toCountryName?.isNotEmpty ?? false) ||
      (toPortName?.isNotEmpty ?? false);

  ShippingSearchFilters copyWith({
    String? fromCountryName,
    String? fromPortName,
    String? toCountryName,
    String? toPortName,
    bool clearFromPort = false,
    bool clearToPort = false,
  }) {
    return ShippingSearchFilters(
      fromCountryName: fromCountryName ?? this.fromCountryName,
      fromPortName: clearFromPort ? null : fromPortName ?? this.fromPortName,
      toCountryName: toCountryName ?? this.toCountryName,
      toPortName: clearToPort ? null : toPortName ?? this.toPortName,
    );
  }
}

class ShippingFilterSheet extends StatefulWidget {
  const ShippingFilterSheet({
    super.key,
    required this.initialFilters,
  });

  final ShippingSearchFilters initialFilters;

  static Future<ShippingSearchFilters?> show(
    BuildContext context, {
    required ShippingSearchFilters initialFilters,
  }) {
    return showModalBottomSheet<ShippingSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => ShippingFilterSheet(initialFilters: initialFilters),
    );
  }

  @override
  State<ShippingFilterSheet> createState() => _ShippingFilterSheetState();
}

class _ShippingFilterSheetState extends State<ShippingFilterSheet> {
  late String? _fromCountry;
  late String? _fromPort;
  late String? _toCountry;
  late String? _toPort;

  List<String> _countries = const [];
  List<String> _fromPorts = const [];
  List<String> _toPorts = const [];
  bool _isLoadingCountries = true;
  bool _isLoadingFromPorts = false;
  bool _isLoadingToPorts = false;

  @override
  void initState() {
    super.initState();
    _fromCountry = widget.initialFilters.fromCountryName;
    _fromPort = widget.initialFilters.fromPortName;
    _toCountry = widget.initialFilters.toCountryName;
    _toPort = widget.initialFilters.toPortName;
    _loadCountries();
    if (_fromCountry != null && _fromCountry!.isNotEmpty) {
      _loadPorts(_fromCountry!, isFrom: true, selectedPort: _fromPort);
    }
    if (_toCountry != null && _toCountry!.isNotEmpty) {
      _loadPorts(_toCountry!, isFrom: false, selectedPort: _toPort);
    }
  }

  Future<void> _loadCountries() async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.geoCountriesEndPoint,
      );
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final parsed = GeoCountriesResponse.fromJson(data);
        setState(() {
          _countries = parsed.countries;
          _isLoadingCountries = false;
        });
      } else {
        setState(() => _isLoadingCountries = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCountries = false);
    }
  }

  Future<void> _loadPorts(
    String country, {
    required bool isFrom,
    String? selectedPort,
  }) async {
    setState(() {
      if (isFrom) {
        _isLoadingFromPorts = true;
      } else {
        _isLoadingToPorts = true;
      }
    });

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.geoPortsByCountryEndPoint(country),
      );
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final parsed = GeoPortsResponse.fromJson(data);
        final portNames = parsed.ports.map((port) => port.displayName).toList();
        setState(() {
          if (isFrom) {
            _fromPorts = portNames;
            _isLoadingFromPorts = false;
            if (selectedPort != null && !_fromPorts.contains(selectedPort)) {
              _fromPort = null;
            }
          } else {
            _toPorts = portNames;
            _isLoadingToPorts = false;
            if (selectedPort != null && !_toPorts.contains(selectedPort)) {
              _toPort = null;
            }
          }
        });
      } else {
        setState(() {
          if (isFrom) {
            _isLoadingFromPorts = false;
          } else {
            _isLoadingToPorts = false;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _isLoadingFromPorts = false;
        } else {
          _isLoadingToPorts = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24.w,
        16.h,
        24.w,
        24.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5D5),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Shipping filters',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: 20.h),
          _buildDropdown(
            label: 'From country',
            value: _fromCountry,
            items: _countries,
            isLoading: _isLoadingCountries,
            onChanged: (value) {
              setState(() {
                _fromCountry = value;
                _fromPort = null;
                _fromPorts = const [];
              });
              if (value != null) {
                _loadPorts(value, isFrom: true);
              }
            },
          ),
          SizedBox(height: 12.h),
          _buildDropdown(
            label: 'From port',
            value: _fromPort,
            items: _fromPorts,
            isLoading: _isLoadingFromPorts,
            enabled: _fromCountry != null,
            onChanged: (value) => setState(() => _fromPort = value),
          ),
          SizedBox(height: 12.h),
          _buildDropdown(
            label: 'To country',
            value: _toCountry,
            items: _countries,
            isLoading: _isLoadingCountries,
            onChanged: (value) {
              setState(() {
                _toCountry = value;
                _toPort = null;
                _toPorts = const [];
              });
              if (value != null) {
                _loadPorts(value, isFrom: false);
              }
            },
          ),
          SizedBox(height: 12.h),
          _buildDropdown(
            label: 'To port',
            value: _toPort,
            items: _toPorts,
            isLoading: _isLoadingToPorts,
            enabled: _toCountry != null,
            onChanged: (value) => setState(() => _toPort = value),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const ShippingSearchFilters(),
                    );
                  },
                  child: const Text('Clear'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: PrimaryButton(
                  text: 'Apply',
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ShippingSearchFilters(
                        fromCountryName: _fromCountry,
                        fromPortName: _fromPort,
                        toCountryName: _toCountry,
                        toPortName: _toPort,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: LightColor.greyTextColor,
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          value: value != null && items.contains(value) ? value : null,
          isExpanded: true,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          ),
          hint: Text(isLoading ? 'Loading...' : 'Select $label'),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: enabled && !isLoading ? onChanged : null,
        ),
      ],
    );
  }
}
