import 'package:alrasmarket/core/constants/country_names.dart';
import 'package:alrasmarket/core/constants/uae_retail_emirates.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/data/models/geo_city_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/address_usecases.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/location_picker_map_view.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

class AddAddressDialog extends StatefulWidget {
  const AddAddressDialog({super.key, this.retailMode = false});

  /// When true, only UAE and the seven domestic shipping emirates are shown.
  final bool retailMode;

  static Future<bool?> show(
    BuildContext context, {
    bool retailMode = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddAddressDialog(retailMode: retailMode),
    );
  }

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _getCitiesUseCase = sl<GetGeoCitiesByCountryUseCase>();
  final _createAddressUseCase = sl<CreateClientAddressUseCase>();

  String? _selectedCountry;
  String? _selectedCityId;
  List<GeoCityModel> _cities = [];
  bool _isCitiesLoading = false;
  bool _isResolvingLocation = false;
  bool _isSubmitting = false;
  LatLng? _pickedCoordinates;

  @override
  void initState() {
    super.initState();
    final defaultCountry = widget.retailMode
        ? UaeRetailEmirates.countryEn
        : 'United Arab Emirates';
    _selectedCountry = defaultCountry;
    _loadCities(defaultCountry);
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadCities(String country) async {
    setState(() {
      _isCitiesLoading = true;
      _selectedCityId = null;
      _cities = [];
    });

    final result = await _getCitiesUseCase(country);
    if (!mounted) return;

    result.fold(
      (failure) {
        AppToast.showError(context, failure.message);
        setState(() => _isCitiesLoading = false);
      },
      (response) {
        var cities = response.items;
        if (widget.retailMode) {
          cities = UaeRetailEmirates.dedupeByCanonicalEmirate(
            cities.where(
              (city) => UaeRetailEmirates.matchesCityName(city.cityName),
            ),
            (city) => city.cityName,
          );
        }
        setState(() {
          _cities = cities;
          _isCitiesLoading = false;
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCountry == null || _selectedCityId == null) {
      AppToast.showError(context, S.of(context).thisFieldIsRequired);
      return;
    }

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      AppToast.showError(context, S.of(context).pleaseLoginToPublish);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _createAddressUseCase(
      token: token,
      request: CreateAddressRequest(
        cityId: _selectedCityId!,
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        AppToast.showError(context, failure.message);
      },
      (_) => Navigator.of(context).pop(true),
    );
  }

  Future<void> _pickCurrentLocation() async {
    setState(() => _isResolvingLocation = true);
    try {
      final position = await _resolveCurrentPosition();
      if (!mounted) return;
      await _applyCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResolvingLocation = false);
    }
  }

  Future<void> _pickLocationFromMap() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final initial = _pickedCoordinates ?? const LatLng(25.2048, 55.2708);
    final picked = await LocationPickerMapView.pick(
      context,
      initialPosition: initial,
      title: isArabic ? 'اختيار الموقع' : 'Pick location',
      confirmLabel: isArabic ? 'تأكيد الموقع' : 'Confirm location',
    );
    if (picked == null || !mounted) return;

    setState(() => _isResolvingLocation = true);
    try {
      await _applyCoordinates(picked.latitude, picked.longitude);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResolvingLocation = false);
    }
  }

  Future<Position> _resolveCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please enable location services.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _applyCoordinates(double lat, double lng) async {
    _pickedCoordinates = LatLng(lat, lng);

    final placemarks = await placemarkFromCoordinates(lat, lng);
    final place = placemarks.isNotEmpty ? placemarks.first : null;
    if (place == null) return;

    final country = place.country?.trim();
    if (country != null && country.isNotEmpty && country != _selectedCountry) {
      _selectedCountry = country;
      await _loadCities(country);
      if (!mounted) return;
    }

    final cityCandidate = (place.locality?.trim().isNotEmpty == true
            ? place.locality!.trim()
            : null) ??
        (place.subAdministrativeArea?.trim().isNotEmpty == true
            ? place.subAdministrativeArea!.trim()
            : null) ??
        (place.administrativeArea?.trim().isNotEmpty == true
            ? place.administrativeArea!.trim()
            : null);

    if (cityCandidate != null) {
      final matched = _cities.firstWhere(
        (c) => _normalizeName(c.cityName) == _normalizeName(cityCandidate),
        orElse: () => const GeoCityModel(cityId: '', cityName: ''),
      );
      if (matched.cityId.isNotEmpty) {
        _selectedCityId = matched.cityId;
      }
    }

    final line1 = <String>[
      if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
      if ((place.subLocality ?? '').trim().isNotEmpty) place.subLocality!.trim(),
      if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
    ].join(', ');
    if (line1.isNotEmpty) {
      _addressLine1Controller.text = line1;
    }

    setState(() {});
  }

  String _normalizeName(String value) {
    final lower = value.toLowerCase().trim();
    return lower
        .replaceAll('emirate of ', '')
        .replaceAll(' محافظة', '')
        .replaceAll(' إمارة', '');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final countryItems = widget.retailMode
        ? [UaeRetailEmirates.countryEn]
        : AppCountryNames.all;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        s.addNewAddress,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isResolvingLocation ? null : _pickCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: Text(
                          isArabic ? 'موقعي الحالي' : 'Current location',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _isResolvingLocation ? null : _pickLocationFromMap,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          isArabic ? 'اختيار من الخريطة' : 'Pick from map',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_pickedCoordinates != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Lat: ${_pickedCoordinates!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_pickedCoordinates!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontFamily: fontFamily,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                _dropdownField(
                  fontFamily: fontFamily,
                  hint: s.countryOfOrigin,
                  value: _selectedCountry,
                  items: countryItems,
                  itemLabels: widget.retailMode
                      ? {
                          UaeRetailEmirates.countryEn:
                              UaeRetailEmirates.countryLabel(isArabic),
                        }
                      : null,
                  enabled: !widget.retailMode,
                  onChanged: widget.retailMode
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedCountry = value);
                          _loadCities(value);
                        },
                ),
                SizedBox(height: 12.h),
                _dropdownField(
                  fontFamily: fontFamily,
                  hint: widget.retailMode
                      ? (isArabic ? 'الإمارة' : s.deliveryEmirate)
                      : (_isCitiesLoading ? 'Loading...' : s.city),
                  value: _selectedCityId,
                  items: _cities.map((city) => city.cityId).toList(),
                  itemLabels: {
                    for (final city in _cities)
                      city.cityId: widget.retailMode
                          ? UaeRetailEmirates.displayName(
                              city.cityName,
                              isArabic,
                            )
                          : city.cityName,
                  },
                  isLoading: _isCitiesLoading,
                  enabled: _selectedCountry != null && _cities.isNotEmpty,
                  onChanged: (value) => setState(() => _selectedCityId = value),
                ),
                SizedBox(height: 12.h),
                CustomTextFormField(
                  controller: _addressLine1Controller,
                  label: s.addressLine1,
                  hintText: s.enterAddressLine1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return s.thisFieldIsRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                CustomTextFormField(
                  controller: _addressLine2Controller,
                  label: s.addressLine2Optional,
                  hintText: s.enterAddressLine2Optional,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        PrimaryButton(
          text: s.save,
          height: 40.h,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String fontFamily,
    required String hint,
    required String? value,
    required List<String> items,
    Map<String, String>? itemLabels,
    bool isLoading = false,
    bool enabled = true,
    ValueChanged<String?>? onChanged,
  }) {
    final canChange = enabled && !isLoading && onChanged != null;
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      hint: Text(
        hint,
        style: TextStyle(
          color: const Color(0xFF333333).withValues(alpha: 0.4),
          fontFamily: fontFamily,
          fontSize: 14.sp,
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF6B7280),
              size: 20.sp,
            ),
      dropdownColor: Colors.white,
      menuMaxHeight: 320.h,
      style: TextStyle(
        color: const Color(0xFF333333),
        fontFamily: fontFamily,
        fontSize: 14.sp,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                itemLabels?[item] ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: canChange ? onChanged : null,
    );
  }
}
