import 'package:alrasmarket/core/serveses/pending_profile_image_uploader.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/auth/presentation/views/widgets/contry_code.dart';
import 'package:alrasmarket/features/auth/presentation/views/widgets/auth_profile_photo_picker.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.isSupplierCompany});

  final bool isSupplierCompany;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landlinePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCustomerCompany = false;
  String _selectedCountryCode = '+971';
  String _selectedOtherCountryCode = '+971';
  bool _acceptedTermsAndPrivacy = false;
  bool _resolvingAddress = false;
  String? _profileImagePath;

  @override
  void dispose() {
    _companyNameController.dispose();
    _licenseNumberController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _landlinePhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fillAddressFromLocation() async {
    if (_resolvingAddress) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _resolvingAddress = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          isAr
              ? 'من فضلك فعّل خدمة الموقع أولاً.'
              : 'Please enable location services.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          isAr
              ? 'صلاحية الموقع مطلوبة لتحديد العنوان.'
              : 'Location permission is required.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = places.isNotEmpty ? places.first : null;
      if (place == null) {
        throw Exception(
          isAr
              ? 'تعذر قراءة العنوان من موقعك الحالي.'
              : 'Could not resolve address from your location.',
        );
      }
      final line = <String>[
        if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty) place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
      ].join(', ');
      if (line.isEmpty) {
        throw Exception(
          isAr
              ? 'تعذر قراءة العنوان من موقعك الحالي.'
              : 'Could not resolve address from your location.',
        );
      }
      if (!mounted) return;
      setState(() {
        _addressController.text = line;
      });
      AppToast.showSuccess(
        context,
        isAr
            ? 'تم تعبئة العنوان من موقعك الحالي.'
            : 'Address filled from your current location.',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Widget _buildCompanyLocationAndTaxSection({required bool isArabic}) {
    final s = S.of(context);
    final addressLabel = isArabic ? 'الموقع / العنوان' : 'Location / Address';
    final pickLabel =
        isArabic ? 'تحديد موقعي الحالي' : 'Use my current location';
    final hint = isArabic
        ? 'اضغط لتحديد موقعك، وسيُملأ العنوان تلقائيًا'
        : 'Tap to detect your location and auto-fill address';

    final locationPicker = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          addressLabel,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        SizedBox(height: 8.h),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            onTap: _resolvingAddress ? null : _fillAddressFromLocation,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: LightColor.defaultColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: _resolvingAddress
                        ? Padding(
                            padding: EdgeInsets.all(10.w),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            color: LightColor.defaultColor,
                            size: 22.sp,
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickLabel,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: LightColor.defaultColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _addressController.text.trim().isEmpty
                              ? hint
                              : _addressController.text.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF667085),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF98A2B3),
                    size: 22.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Keep a hidden/required text field so Form validation still works,
        // while UI uses the location picker above.
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            child: TextFormField(
              controller: _addressController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return s.thisFieldIsRequired;
                }
                return null;
              },
            ),
          ),
        ),
        // Only show required hint when empty and form not yet validating via toast.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _addressController,
          builder: (context, value, _) {
            if (value.text.trim().isNotEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                isArabic
                    ? 'الموقع مطلوب — اضغط لتحديده'
                    : 'Location is required — tap to detect it',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFD92D20),
                ),
              ),
            );
          },
        ),
      ],
    );

    final licenseField = CustomTextFormField(
      controller: _licenseNumberController,
      label: s.tradeLicenseNumber,
      addOptionalLabel: true,
      hintText: s.enterTradeLicenseNumber,
    );

    final taxField = CustomTextFormField(
      controller: _taxNumberController,
      label: s.taxNumber,
      hintText: s.taxNumber,
      addOptionalLabel: true,
    );

    final websiteField = CustomTextFormField(
      controller: _websiteController,
      label: s.website,
      hintText: s.websiteHint,
      addOptionalLabel: true,
      keyboardType: TextInputType.url,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty || trimmed == 'https://' || trimmed == 'http://') {
          return null;
        }
        final candidate = trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';
        final uri = Uri.tryParse(candidate);
        if (uri == null || !uri.hasScheme || (uri.host.isEmpty)) {
          return s.invalidWebsite;
        }
        return null;
      },
    );

    return Column(
      children: [
        if (isArabic) ...[
          licenseField,
          SizedBox(height: 12.h),
          locationPicker,
        ] else ...[
          locationPicker,
          SizedBox(height: 12.h),
          licenseField,
        ],
        SizedBox(height: 12.h),
        taxField,
        SizedBox(height: 12.h),
        websiteField,
      ],
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(value);
  }

  String _accountTypeLabel(BuildContext context) {
    if (_isCustomerCompany) return S.of(context).company;
    return S.of(context).person;
  }

  void _handleRegister() {
    if (!_acceptedTermsAndPrivacy) {
      AppToast.showError(
        context,
        S.of(context).mustAcceptTermsAndPrivacy,
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';
    if (widget.isSupplierCompany || _isCustomerCompany) {
      context.push(
        AppRoutes.kCompletRegisterView,
        extra: {
          'isCompany': true,
          'fullName': _companyNameController.text.trim(),
          'companyName': _companyNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phoneNumber': fullPhone,
          'landNumber':
              '$_selectedOtherCountryCode ${_landlinePhoneController.text.trim()}',
          'licenseNumber': _licenseNumberController.text.trim(),
          'commercialRegister': _addressController.text.trim(),
          'taxNumber': _taxNumberController.text.trim(),
          'website': _websiteController.text.trim(),
          'isCustomerCompany': _isCustomerCompany,
        },
      );
      return;
    }

    AuthCubit.get(context).registerPerson(
      fullName: _companyNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phoneNumber: fullPhone,
    );
    PendingProfileImageUploader.setPending(_profileImagePath);
  }

  Widget _buildTermsAcceptanceRow() {
    final s = S.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24.h,
          width: 24.w,
          child: Checkbox(
            value: _acceptedTermsAndPrivacy,
            activeColor: LightColor.defaultColor,
            side: BorderSide(color: LightColor.defaultColor, width: 1.5.w),
            onChanged: (value) {
              setState(() {
                _acceptedTermsAndPrivacy = value ?? false;
              });
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  s.agreeToTermsPrefix,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xCC333333),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.kTermsAndConditions),
                  child: Text(
                    s.policyAndPrivacy,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: LightColor.defaultColor,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                       decorationColor: LightColor.defaultColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F7FF),
        body: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is RegisterClientSuccessState) {
              AppToast.showSuccess(
                context,
                S.of(context).accountCreatedSuccessfully,
              );
              context.push(
                AppRoutes.kOtpVerificationView,
                extra: {
                  'email': _emailController.text.trim(),
                  'isCompany': false,
                },
              );
            } else if (state is RegisterClientErrorState) {
              AppToast.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is RegisterClientLoadingState;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(),
                    SizedBox(height: 24.h),
                    Stack(
                      alignment:
                          Alignment.center, // هيخلي أي عنصر في النص بالظبط
                      children: [
                        // 1. النص في منتصف السطر تماماً
                        Text(
                          S.of(context).createAccount,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),

                        // 2. القائمة المنسدلة على الطرف
                        if (!widget.isSupplierCompany)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,

                            children: [
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                offset: Offset(0, 28.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                color: Colors.white,
                                onSelected: (value) {
                                  setState(() {
                                    _isCustomerCompany = value == 'company';
                                  });
                                },
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem(
                                      value: 'person',
                                      child: Text(S.of(context).person),
                                    ),
                                    PopupMenuItem(
                                      value: 'company',
                                      child: Text(S.of(context).company),
                                    ),
                                  ];
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _accountTypeLabel(context),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20.sp,
                                      color: LightColor.defaultColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    if (!widget.isSupplierCompany && !_isCustomerCompany) ...[
                      Center(
                        child: AuthProfilePhotoPicker(
                          initialPath: _profileImagePath,
                          onChanged: (path) => _profileImagePath = path,
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    CustomTextFormField(
                      controller: _companyNameController,
                      label: widget.isSupplierCompany || _isCustomerCompany
                          ? S.of(context).companyName
                          : S.of(context).fullName,
                      hintText: widget.isSupplierCompany || _isCustomerCompany
                          ? S.of(context).enterCompanyName
                          : S.of(context).enterFullName,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).thisFieldIsRequired;
                        }
                        return null;
                      },
                    ),
                    if (widget.isSupplierCompany || _isCustomerCompany) ...[
                      _buildCompanyLocationAndTaxSection(
                        isArabic:
                            Localizations.localeOf(context).languageCode == 'ar',
                      ),
                      SizedBox(height: 12.h),
                    ],
                    if (Localizations.localeOf(context).languageCode == "en")
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: CountryCodeField(
                                  label: S.of(context).countryCode,
                                  value: _selectedCountryCode,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCountryCode = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                flex: 3,
                                child: CustomTextFormField(
                                  controller: _phoneController,
                                  label: S.of(context).phoneNumber,
                                  hintText: 'XX XXX XXXX',
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return S.of(context).thisFieldIsRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (widget.isSupplierCompany ||
                              _isCustomerCompany) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: CountryCodeField(
                                    label: S.of(context).countryCode,
                                    value: _selectedOtherCountryCode,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedOtherCountryCode = value;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  flex: 3,
                                  child: CustomTextFormField(
                                    controller: _landlinePhoneController,
                                    label: S.of(context).landlinePhone,
                                    hintText: 'XX XXX XXXX',
                                    addOptionalLabel: true,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    if (Localizations.localeOf(context).languageCode == "ar")
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: CustomTextFormField(
                                  controller: _phoneController,
                                  label: S.of(context).phoneNumber,
                                  hintText: 'XX XXX XXXX',
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return S.of(context).thisFieldIsRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                flex: 2,
                                child: CountryCodeField(
                                  label: S.of(context).countryCode,
                                  value: _selectedCountryCode,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCountryCode = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (widget.isSupplierCompany ||
                              _isCustomerCompany) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: CustomTextFormField(
                                    controller: _landlinePhoneController,
                                    label: S.of(context).landlinePhone,
                                    hintText: 'XX XXX XXXX',
                                    addOptionalLabel: true,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  flex: 2,
                                  child: CountryCodeField(
                                    label: S.of(context).countryCode,
                                    value: _selectedOtherCountryCode,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedOtherCountryCode = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    SizedBox(height: 12.h),
                    CustomTextFormField(
                      controller: _emailController,
                      label: S.of(context).email,
                      hintText: S.of(context).enterYourEmail,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).thisFieldIsRequired;
                        }
                        if (!_isValidEmail(value.trim())) {
                          return S.of(context).invalidEmail;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    CustomTextFormField(
                      controller: _passwordController,
                      label: S.of(context).password,
                      hintText: S.of(context).enterYourPassword,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).thisFieldIsRequired;
                        }
                        if (value.trim().length < 6) {
                          return S.of(context).passwordMustBeAtLeast6Characters;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildTermsAcceptanceRow(),
                    SizedBox(height: 20.h),
                    PrimaryButton(
                      text: widget.isSupplierCompany || _isCustomerCompany
                          ? S.of(context).next
                          : S.of(context).signUp,
                      onPressed: isLoading ? null : _handleRegister,
                      isLoading: isLoading,
                      backgroundColor: LightColor.defaultColor,
                      borderRadius: 10,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).noAccount,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xCC333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            S.of(context).login,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: LightColor.defaultColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
