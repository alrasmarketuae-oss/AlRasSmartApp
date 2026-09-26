import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/features/auth/data/pending_registration_address.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/auth/presentation/views/widgets/contry_code.dart';
import 'package:alrasmarket/features/auth/presentation/views/widgets/auth_profile_photo_picker.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/add_address_dialog.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

const Color _kBg = Color(0xFFF7FAFF);
const Color _kTitle = Color(0xFF1B3B5F);
const Color _kSubtitle = Color(0xFF8A97AB);
const Color _kLabel = Color(0xFF33455C);
const Color _kHint = Color(0xFF9AA6B8);
const Color _kBorder = Color(0xFFE6ECF5);
const Color _kPrimary = Color(0xFF3A7DC5);

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landlinePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedCountryCode = '+971';
  String _selectedOtherCountryCode = '+971';
  bool _acceptedTermsAndPrivacy = false;
  CreateAddressRequest? _pendingAddress;
  String? _profileImagePath;

  @override
  void dispose() {
    _companyNameController.dispose();
    _ownerNameController.dispose();
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

  Future<void> _collectStructuredAddress() async {
    final collected = await AddAddressDialog.collect(context);
    if (!mounted || collected == null) return;
    final summary = [
      collected.addressLine1.trim(),
      collected.cityName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(', ');
    setState(() {
      _pendingAddress = collected;
      _addressController.text = summary;
    });
    PendingRegistrationAddress.store(collected);
  }

  Widget _buildCompanyLocationAndTaxSection({
    required bool isArabic,
    required bool includeCompanyDocs,
  }) {
    final s = S.of(context);
    final addressLabel = isArabic ? 'الموقع / العنوان' : 'Location / Address';
    final pickLabel = isArabic ? 'تحديد الموقع' : 'Set location';
    final hint = isArabic
        ? 'اضغط لاختيار موقعك الحالي أو التحديد من الخريطة'
        : 'Tap to use current location or pick from the map';

    final locationPicker = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          addressLabel,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _kLabel,
          ),
        ),
        SizedBox(height: 8.h),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            onTap: _collectStructuredAddress,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                            Icons.add_location_alt_outlined,
                            color: _kPrimary,
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
                            color: _kPrimary,
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
                            color: _kSubtitle,
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
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _addressController,
          builder: (context, value, _) {
            if (value.text.trim().isNotEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                isArabic
                    ? 'الموقع مطلوب — اضغط لتحديده (موقعي الحالي أو الخريطة)'
                    : 'Location is required — tap to choose current location or map',
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

    final licenseField = _iconField(
      controller: _licenseNumberController,
      label: s.tradeLicenseNumber,
      hintText: s.enterTradeLicenseNumber,
      icon: Icons.badge_outlined,
    );

    final taxField = _iconField(
      controller: _taxNumberController,
      label: s.taxNumber,
      hintText: s.taxNumber,
      icon: Icons.receipt_long_outlined,
    );

    final websiteField = _iconField(
      controller: _websiteController,
      label: s.website,
      hintText: s.websiteHint,
      icon: Icons.language_outlined,
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
        if (includeCompanyDocs && isArabic) ...[
          licenseField,
          SizedBox(height: 14.h),
          locationPicker,
        ] else if (includeCompanyDocs) ...[
          locationPicker,
          SizedBox(height: 14.h),
          licenseField,
        ] else
          locationPicker,
        if (includeCompanyDocs) ...[
          SizedBox(height: 14.h),
          taxField,
          SizedBox(height: 14.h),
          websiteField,
        ],
      ],
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(value);
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

    if (_pendingAddress == null) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      AppToast.showError(
        context,
        isAr ? 'من فضلك حدد العنوان أولاً.' : 'Please set your address first.',
      );
      return;
    }
    PendingRegistrationAddress.store(_pendingAddress!);

    final fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';
    // All email/password signups register as supplier; roles can be changed in admin dashboard.
    context.push(
      AppRoutes.kCompletRegisterView,
      extra: {
        'isCompany': true,
        'fullName': _ownerNameController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phoneNumber': fullPhone,
        'landNumber':
            '$_selectedOtherCountryCode ${_landlinePhoneController.text.trim()}',
        'licenseNumber': _licenseNumberController.text.trim(),
        'commercialRegister': '',
        'taxNumber': _taxNumberController.text.trim(),
        'website': _websiteController.text.trim(),
        'isCustomerCompany': false,
        'isSupplierCompany': true,
        'profileImagePath': _profileImagePath,
      },
    );
  }

  Widget _buildTermsAcceptanceRow() {
    final s = S.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 22.h,
          width: 22.w,
          child: Checkbox(
            value: _acceptedTermsAndPrivacy,
            activeColor: _kPrimary,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: _kPrimary, width: 1.5.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
            onChanged: (value) {
              setState(() {
                _acceptedTermsAndPrivacy = value ?? false;
              });
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                s.agreeToTermsPrefix,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _kLabel,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.kTermsAndConditions),
                child: Text(
                  s.policyAndPrivacy,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _kPrimary,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Field with Material prefix icon (mockup style) while reusing validators.
  Widget _iconField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _kLabel,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _kTitle,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 13.sp, color: _kHint),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 14.h,
              ),
              prefixIcon: Icon(icon, size: 20.sp, color: _kHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: _kPrimary, width: 1.2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFFD92D20)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return _PasswordField(
      controller: _passwordController,
      label: S.of(context).password,
      hintText: S.of(context).enterYourPassword,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context).thisFieldIsRequired;
        }
        if (value.trim().length < 6) {
          return S.of(context).passwordMustBeAtLeast6Characters;
        }
        return null;
      },
    );
  }

  Widget _phoneRow() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final code = CountryCodeField(
      label: S.of(context).countryCode,
      value: _selectedCountryCode,
      onChanged: (value) {
        setState(() {
          _selectedCountryCode = value;
        });
      },
    );
    final phone = _iconField(
      controller: _phoneController,
      label: S.of(context).phoneNumber,
      hintText: 'XX XXX XXXX',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context).thisFieldIsRequired;
        }
        return null;
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isArabic
          ? [
              Expanded(flex: 3, child: phone),
              SizedBox(width: 12.w),
              Expanded(flex: 2, child: code),
            ]
          : [
              Expanded(flex: 2, child: code),
              SizedBox(width: 12.w),
              Expanded(flex: 3, child: phone),
            ],
    );
  }

  Widget _landlineRow() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final code = CountryCodeField(
      label: S.of(context).countryCode,
      value: _selectedOtherCountryCode,
      onChanged: (value) {
        setState(() {
          _selectedOtherCountryCode = value;
        });
      },
    );
    final phone = _iconField(
      controller: _landlinePhoneController,
      label: S.of(context).landlinePhone,
      hintText: 'XX XXX XXXX',
      icon: Icons.phone_in_talk_outlined,
      keyboardType: TextInputType.phone,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isArabic
          ? [
              Expanded(flex: 3, child: phone),
              SizedBox(width: 12.w),
              Expanded(flex: 2, child: code),
            ]
          : [
              Expanded(flex: 2, child: code),
              SizedBox(width: 12.w),
              Expanded(flex: 3, child: phone),
            ],
    );
  }

  Widget _signUpButton({required bool isLoading}) {
    final label = S.of(context).next;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SizedBox(
      height: 50.h,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: isLoading ? null : _handleRegister,
        child: isLoading
            ? SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is RegisterClientErrorState) {
              AppToast.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is RegisterClientLoadingState;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(showBack: true),
                    SizedBox(height: 20.h),
                    Text(
                      S.of(context).createAccount,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        color: _kTitle,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      isAr
                          ? 'انضم إلينا وابدأ الآن'
                          : 'Join us and get started',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: _kSubtitle,
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Align(
                      alignment: isAr
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: AuthProfilePhotoPicker(
                        initialPath: _profileImagePath,
                        onChanged: (path) => _profileImagePath = path,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    _iconField(
                      controller: _companyNameController,
                      label: S.of(context).companyName,
                      hintText: S.of(context).enterCompanyName,
                      icon: Icons.apartment_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).thisFieldIsRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _iconField(
                      controller: _ownerNameController,
                      label: isAr ? 'اسم المالك' : 'Owner name',
                      hintText: isAr
                          ? 'ادخل اسم المالك'
                          : 'Enter owner name',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).thisFieldIsRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _buildCompanyLocationAndTaxSection(
                      isArabic: isAr,
                      includeCompanyDocs: true,
                    ),
                    SizedBox(height: 14.h),
                    _phoneRow(),
                    SizedBox(height: 14.h),
                    _landlineRow(),
                    SizedBox(height: 14.h),
                    _iconField(
                      controller: _emailController,
                      label: S.of(context).email,
                      hintText: S.of(context).enterYourEmail,
                      icon: Icons.mail_outline_rounded,
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
                    SizedBox(height: 14.h),
                    _passwordField(),
                    SizedBox(height: 16.h),
                    _buildTermsAcceptanceRow(),
                    SizedBox(height: 20.h),
                    _signUpButton(isLoading: isLoading),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).noAccount,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _kSubtitle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            S.of(context).login,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: _kPrimary,
                              fontWeight: FontWeight.w800,
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

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?) validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _kLabel,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscure,
            validator: widget.validator,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _kTitle,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(fontSize: 13.sp, color: _kHint),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 14.h,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 20.sp,
                color: _kHint,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20.sp,
                  color: _kHint,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: _kPrimary, width: 1.2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFFD92D20)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
