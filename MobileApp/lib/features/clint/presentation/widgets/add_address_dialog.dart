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
import 'package:alrasmarket/features/company/data/models/geo_response_models.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

/// Selectable entry backing the country and city search fields.
class _GeoOption {
  const _GeoOption({required this.id, required this.label});

  final String id;
  final String label;
}

class AddAddressDialog extends StatefulWidget {
  const AddAddressDialog({super.key, this.retailMode = false, this.existing});

  /// When true, only UAE and the seven domestic shipping emirates are shown,
  /// because retail shipping is priced per emirate.
  final bool retailMode;

  /// When set, the dialog edits this address instead of creating a new one.
  final ClientAddressModel? existing;

  static Future<bool?> show(
    BuildContext context, {
    bool retailMode = false,
    ClientAddressModel? existing,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddAddressDialog(retailMode: retailMode, existing: existing),
    );
  }

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();

  final _getCountriesUseCase = sl<GetGeoCountryListUseCase>();
  final _getCitiesByIdUseCase = sl<GetGeoCitiesByCountryIdUseCase>();
  final _getCitiesByNameUseCase = sl<GetGeoCitiesByCountryUseCase>();
  final _createAddressUseCase = sl<CreateClientAddressUseCase>();
  final _updateAddressUseCase = sl<UpdateClientAddressUseCase>();

  List<GeoCountryModel> _countries = [];
  GeoCountryModel? _selectedCountry;
  List<_GeoOption> _cityOptions = [];
  int? _citiesLoadedForCountryId;
  bool _isCountriesLoading = false;
  bool _isCitiesLoading = false;
  bool _isResolvingLocation = false;
  bool _isSubmitting = false;
  LatLng? _pickedCoordinates;

  bool get _isEditing => widget.existing != null;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _addressLine1Controller.text = existing.addressLine1;
      _addressLine2Controller.text = existing.addressLine2 ?? '';
      _cityController.text = existing.cityName;
    }
    _countryFocusNode.addListener(_handleCountryFocusChange);
    _cityFocusNode.addListener(_handleCityFocusChange);
    _loadCountries();
  }

  @override
  void dispose() {
    _countryFocusNode.removeListener(_handleCountryFocusChange);
    _cityFocusNode.removeListener(_handleCityFocusChange);
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _countryFocusNode.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  /// The country must be a real row, so a half-typed name reverts on blur.
  void _handleCountryFocusChange() {
    if (_countryFocusNode.hasFocus || !mounted) return;

    final typed = _findCountryByName(_countryController.text);
    if (typed != null) {
      _selectCountry(typed);
      return;
    }
    _countryController.text = _selectedCountry?.displayName(_isArabic) ?? '';
  }

  /// Retail delivery is priced per emirate, so only a listed one may stay.
  void _handleCityFocusChange() {
    if (!widget.retailMode || _cityFocusNode.hasFocus || !mounted) return;
    if (_matchTypedCity() == null) {
      _cityController.clear();
    }
  }

  Future<void> _loadCountries() async {
    setState(() => _isCountriesLoading = true);

    final result = await _getCountriesUseCase();
    if (!mounted) return;

    result.fold(
      (failure) {
        AppToast.showError(context, failure.message);
        setState(() => _isCountriesLoading = false);
        // Retail checkout is UAE-only, so cities can still be listed by name.
        if (widget.retailMode) _loadCities();
      },
      (countries) {
        setState(() {
          _countries = countries;
          _isCountriesLoading = false;
        });
        _applyDefaultCountry();
      },
    );
  }

  void _applyDefaultCountry() {
    final existing = widget.existing;
    GeoCountryModel? initial;

    if (!widget.retailMode && existing != null) {
      initial = _findCountryById(existing.countryId) ??
          _findCountryByName(existing.countryNameEn);
    }
    initial ??= _findCountryByName(UaeRetailEmirates.countryEn) ??
        (_countries.isNotEmpty ? _countries.first : null);

    if (initial == null) return;
    _selectCountry(initial);
  }

  GeoCountryModel? _findCountryById(int countryId) {
    if (countryId <= 0) return null;
    for (final country in _countries) {
      if (country.countryId == countryId) return country;
    }
    return null;
  }

  GeoCountryModel? _findCountryByName(String? name) {
    final needle = _normalize(name ?? '');
    if (needle.isEmpty) return null;
    for (final country in _countries) {
      if (_normalize(country.nameEn) == needle ||
          _normalize(country.nameAr ?? '') == needle ||
          _normalize(country.iso2Code) == needle) {
        return country;
      }
    }
    return null;
  }

  void _selectCountry(GeoCountryModel country) {
    final previous = _selectedCountry;
    if (previous?.countryId == country.countryId &&
        _citiesLoadedForCountryId == country.countryId) {
      return;
    }

    setState(() {
      _selectedCountry = country;
      _countryController.text = country.displayName(_isArabic);
      _cityOptions = [];
      // A city from the previous country must not be saved under the new one.
      if (previous != null && previous.countryId != country.countryId) {
        _cityController.clear();
      }
    });
    _loadCities();
  }

  Future<void> _loadCities() async {
    final country = _selectedCountry;
    final lookupName = country?.nameEn ??
        (widget.retailMode ? UaeRetailEmirates.countryEn : '');
    if (country == null && lookupName.isEmpty) return;

    setState(() {
      _isCitiesLoading = true;
      _cityOptions = [];
    });

    final result = country != null
        ? await _getCitiesByIdUseCase(country.countryId)
        : await _getCitiesByNameUseCase(lookupName);
    if (!mounted) return;

    _citiesLoadedForCountryId = country?.countryId ?? 0;

    result.fold(
      (failure) {
        // A country with no cities is expected outside the UAE; the user types one.
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
          _cityOptions = [
            for (final city in cities)
              _GeoOption(id: city.cityId, label: _cityLabel(city)),
          ];
          _isCitiesLoading = false;
        });
      },
    );
  }

  String _cityLabel(GeoCityModel city) => widget.retailMode
      ? UaeRetailEmirates.displayName(city.cityName, _isArabic)
      : city.cityName;

  _GeoOption? _matchTypedCity() {
    final typed = _normalize(_cityController.text);
    if (typed.isEmpty) return null;
    for (final option in _cityOptions) {
      if (_normalize(option.label) == typed) return option;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final country = _selectedCountry;
    final cityName = _cityController.text.trim();
    if (country == null || cityName.isEmpty) {
      AppToast.showError(context, S.of(context).thisFieldIsRequired);
      return;
    }

    final matchedCity = _matchTypedCity();
    if (widget.retailMode && matchedCity == null) {
      AppToast.showError(context, S.of(context).selectDeliveryEmirate);
      return;
    }

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      AppToast.showError(context, S.of(context).pleaseLoginToPublish);
      return;
    }

    setState(() => _isSubmitting = true);

    final request = CreateAddressRequest(
      cityId: matchedCity?.id,
      countryId: country.countryId,
      cityName: cityName,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
    );

    final existing = widget.existing;
    final result = existing == null
        ? await _createAddressUseCase(token: token, request: request)
        : await _updateAddressUseCase(
            addressId: existing.addressId,
            token: token,
            request: request,
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
    final initial = _pickedCoordinates ?? const LatLng(25.2048, 55.2708);
    final picked = await LocationPickerMapView.pick(
      context,
      initialPosition: initial,
      title: _isArabic ? 'اختيار الموقع' : 'Pick location',
      confirmLabel: _isArabic ? 'تأكيد الموقع' : 'Confirm location',
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

    if (!widget.retailMode) {
      final resolved = _findCountryByName(place.country) ??
          _findCountryByName(place.isoCountryCode);
      if (resolved != null && resolved.countryId != _selectedCountry?.countryId) {
        _selectCountry(resolved);
      }
    }

    final cityCandidate = _firstNonEmpty([
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]);
    if (cityCandidate != null) {
      // Free text is allowed, so the geocoded city is kept even when the
      // country has no cities stored yet.
      _cityController.text = cityCandidate;
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

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('emirate of ', '')
        .replaceAll('محافظة', '')
        .replaceAll('إمارة', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final countryOptions = widget.retailMode
        ? <_GeoOption>[]
        : [
            for (final country in _countries)
              _GeoOption(
                id: country.countryId.toString(),
                label: country.displayName(_isArabic),
              ),
          ];

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        _isEditing ? s.editAddress : s.addNewAddress,
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
                        onPressed:
                            _isResolvingLocation ? null : _pickCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: Text(
                          _isArabic ? 'موقعي الحالي' : 'Current location',
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
                          _isArabic ? 'اختيار من الخريطة' : 'Pick from map',
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
                _searchField(
                  fontFamily: fontFamily,
                  controller: _countryController,
                  focusNode: _countryFocusNode,
                  hint: s.country,
                  options: countryOptions,
                  isLoading: _isCountriesLoading,
                  enabled: !widget.retailMode,
                  onSelected: (option) {
                    final country = _findCountryById(int.parse(option.id));
                    if (country != null) _selectCountry(country);
                  },
                  validator: (_) {
                    if (_selectedCountry == null && !widget.retailMode) {
                      return s.thisFieldIsRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                _searchField(
                  fontFamily: fontFamily,
                  controller: _cityController,
                  focusNode: _cityFocusNode,
                  hint: widget.retailMode ? s.deliveryEmirate : s.searchOrTypeCity,
                  options: _cityOptions,
                  isLoading: _isCitiesLoading,
                  enabled: _selectedCountry != null || widget.retailMode,
                  onSelected: (_) => setState(() {}),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _selectedCountry == null && !widget.retailMode
                          ? s.selectCountryFirst
                          : s.thisFieldIsRequired;
                    }
                    return null;
                  },
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

  /// Type-to-filter field. The typed value survives when it is not in
  /// [options], which is how a city outside the UAE gets added.
  Widget _searchField({
    required String fontFamily,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required List<_GeoOption> options,
    required ValueChanged<_GeoOption> onSelected,
    bool isLoading = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final textStyle = TextStyle(
      color: const Color(0xFF333333),
      fontFamily: fontFamily,
      fontSize: 14.sp,
    );

    return RawAutocomplete<_GeoOption>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (textEditingValue) {
        if (!enabled) return const Iterable<_GeoOption>.empty();
        final query = _normalize(textEditingValue.text);
        if (query.isEmpty) return options;
        return options
            .where((option) => _normalize(option.label).contains(query));
      },
      displayStringForOption: (option) => option.label,
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, node, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: node,
          enabled: enabled && !isLoading,
          style: textStyle,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textStyle.copyWith(
              color: const Color(0xFF333333).withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            suffixIcon: isLoading
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.search_rounded,
                    size: 22.sp,
                    color: const Color(0xFF6B7280),
                  ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelect, results) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 220.h,
                maxWidth: MediaQuery.sizeOf(context).width - 80.w,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final option = results.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    onTap: () => onSelect(option),
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
