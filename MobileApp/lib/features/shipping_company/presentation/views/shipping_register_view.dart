import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/auth/presentation/views/widgets/contry_code.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ShippingRegisterView extends StatefulWidget {
  const ShippingRegisterView({super.key});

  @override
  State<ShippingRegisterView> createState() => _ShippingRegisterViewState();
}

class _ShippingRegisterViewState extends State<ShippingRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedCountryCode = '+971';
  bool _acceptedTermsAndPrivacy = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _commercialRegisterController.dispose();
    _taxNumberController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(value);
  }

  void _handleRegister() {
    if (!_acceptedTermsAndPrivacy) {
      AppToast.showError(context, S.of(context).mustAcceptTermsAndPrivacy);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    AuthCubit.get(context).registerShippingCompany(
      companyName: _companyNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phoneNumber: '$_selectedCountryCode ${_phoneController.text.trim()}',
      commercialRegister: _commercialRegisterController.text.trim(),
      taxNumber: _taxNumberController.text.trim(),
      website: _websiteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffF2F7FF),
        body: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is RegisterSellerSuccessState) {
              AppToast.showSuccess(context, s.accountCreatedSuccessfully);
              context.push(
                AppRoutes.kOtpVerificationView,
                extra: {
                  'email': _emailController.text.trim(),
                  'isShippingCompany': true,
                },
              );
            } else if (state is RegisterSellerErrorState) {
              AppToast.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is RegisterSellerLoadingState;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(),
                    SizedBox(height: 16.h),
                    Center(
                      child: Image.asset(
                        AppAssets.servicesIcon5,
                        width: 56.w,
                        height: 56.w,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      s.shippingCompanyRegister,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      s.shippingCompanyRegisterSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: LightColor.greyTextColor,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    CustomTextFormField(
                      controller: _companyNameController,
                      label: s.shippingCompanyName,
                      hintText: s.enterShippingCompanyName,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? s.thisFieldIsRequired : null,
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormField(
                      controller: _commercialRegisterController,
                      label: s.commercialRegister,
                      hintText: s.commercialRegister,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? s.thisFieldIsRequired : null,
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormField(
                      controller: _taxNumberController,
                      label: s.taxNumber,
                      hintText: s.taxNumber,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? s.thisFieldIsRequired : null,
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormField(
                      controller: _websiteController,
                      label: s.website,
                      hintText: s.websiteHint,
                      addOptionalLabel: true,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty ||
                            trimmed == 'https://' ||
                            trimmed == 'http://') {
                          return null;
                        }
                        final candidate = trimmed.startsWith('http://') ||
                                trimmed.startsWith('https://')
                            ? trimmed
                            : 'https://$trimmed';
                        final uri = Uri.tryParse(candidate);
                        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                          return s.invalidWebsite;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CountryCodeField(
                            label: s.countryCode,
                            value: _selectedCountryCode,
                            onChanged: (value) =>
                                setState(() => _selectedCountryCode = value),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 3,
                          child: CustomTextFormField(
                            controller: _phoneController,
                            label: s.phoneNumber,
                            hintText: 'XX XXX XXXX',
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? s.thisFieldIsRequired : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormField(
                      controller: _emailController,
                      label: s.email,
                      hintText: s.enterYourEmail,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.thisFieldIsRequired;
                        if (!_isValidEmail(v.trim())) return s.invalidEmail;
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    CustomTextFormField(
                      controller: _passwordController,
                      label: s.password,
                      hintText: s.enterYourPassword,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.thisFieldIsRequired;
                        if (v.length < 6) return s.passwordMustBeAtLeast6Characters;
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedTermsAndPrivacy,
                          onChanged: (value) => setState(
                            () => _acceptedTermsAndPrivacy = value ?? false,
                          ),
                          activeColor: LightColor.defaultColor,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _acceptedTermsAndPrivacy = !_acceptedTermsAndPrivacy,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Text(
                                s.mustAcceptTermsAndPrivacy,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: LightColor.greyTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                            text: s.signUp,
                            onPressed: _handleRegister,
                            backgroundColor: LightColor.defaultColor,
                          ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.alreadyHaveAnAccount, style: TextStyle(fontSize: 14.sp)),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            s.login,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: LightColor.defaultColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
