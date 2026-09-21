import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/login_required_sheet.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/delete_account_dialog.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_states.dart';
import 'package:alrasmarket/features/shipping_company/presentation/widgets/shipping_company_widgets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ShippingProfileView extends StatefulWidget {
  const ShippingProfileView({super.key});

  @override
  State<ShippingProfileView> createState() => _ShippingProfileViewState();
}

class _ShippingProfileViewState extends State<ShippingProfileView> {
  final _companyName = TextEditingController();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _landline = TextEditingController();
  final _website = TextEditingController();
  final _commercialRegister = TextEditingController();
  final _taxNumber = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _companyName.dispose();
    _ownerName.dispose();
    _email.dispose();
    _phone.dispose();
    _landline.dispose();
    _website.dispose();
    _commercialRegister.dispose();
    _taxNumber.dispose();
    super.dispose();
  }

  void _fillFromDashboard(ShippingCompanyLoadedState state) {
    if (_initialized) return;
    _applyDashboard(state.dashboard);
    _initialized = true;
  }

  void _applyDashboard(ShippingCompanyDashboardModel dashboard) {
    _companyName.text = dashboard.companyName;
    _ownerName.text = dashboard.fullName;
    _email.text = dashboard.email;
    _phone.text = dashboard.phoneNumber;
    _landline.text = dashboard.landNumber;
    _website.text = dashboard.website;
    _commercialRegister.text = dashboard.commercialRegister;
    _taxNumber.text = dashboard.taxNumber;
  }

  Future<void> _save() async {
    final s = S.of(context);
    final ok = await context.read<ShippingCompanyCubit>().saveProfile(
          companyName: _companyName.text.trim(),
          fullName: _ownerName.text.trim(),
          phoneNumber: _phone.text.trim(),
          landNumber: _landline.text.trim(),
          commercialRegister: _commercialRegister.text.trim(),
          taxNumber: _taxNumber.text.trim(),
          website: _website.text.trim(),
        );
    if (ok && mounted) {
      AppToast.showSuccess(context, s.savedSuccessfully);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final password = await DeleteAccountDialog.show(context);
    if (!mounted || password == null || password.isEmpty) return;
    await context.read<AuthCubit>().deleteAccount(password: password);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    goToGuestHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    return BlocListener<AuthCubit, AuthStates>(
      listenWhen: (_, current) =>
          current is DeleteAccountSuccessState ||
          current is DeleteAccountErrorState,
      listener: (context, state) {
        if (state is DeleteAccountErrorState) {
          AppToast.showError(context, state.message);
          return;
        }
        if (state is DeleteAccountSuccessState) {
          AppToast.showSuccess(context, state.message);
          if (!context.mounted) return;
          context.read<ShippingCompanyCubit>().setTab(0);
          goToGuestHome(context);
        }
      },
      child: BlocBuilder<ShippingCompanyCubit, ShippingCompanyStates>(
        builder: (context, state) {
          final dashboard = state is ShippingCompanyLoadedState
              ? state.dashboard
              : context.read<ShippingCompanyCubit>().dashboard;

          if (state is ShippingCompanyLoadedState) {
            _fillFromDashboard(state);
          } else if (!_initialized && dashboard != null) {
            _applyDashboard(dashboard);
            _initialized = true;
          }

          final stats = dashboard?.stats;
          final loading = state is ShippingCompanyActionLoadingState;
          final isDeletingAccount =
              context.watch<AuthCubit>().state is DeleteAccountLoadingState;

          return Stack(
            children: [
              SingleChildScrollView(
                // Bottom clearance keeps the last row above the animated bottom nav bar.
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                child: Column(
                  children: [
                    Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3C80C8), Color(0xFF64A051)],
                        ),
                      ),
                      child: Icon(Icons.local_shipping_outlined,
                          color: Colors.white, size: 42.sp),
                    ),
                    SizedBox(height: 16.h),
                    if (stats != null) ...[
                      ShippingStatCardsRow(
                        activeCount: stats.activeCount,
                        underReviewCount: stats.underReviewCount,
                        rejectedCount: stats.rejectedCount,
                        activeLabel: s.currentAds,
                        reviewLabel: s.underReviewAds,
                        rejectedLabel: s.rejectedAds,
                      ),
                      SizedBox(height: 20.h),
                    ],
                    ShippingProfileField(
                      label: s.shippingCompanyName,
                      controller: _companyName,
                    ),
                    ShippingProfileField(
                      label: isAr ? 'اسم المالك' : 'Owner name',
                      controller: _ownerName,
                    ),
                    ShippingProfileField(
                      label: s.email,
                      controller: _email,
                      readOnly: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    ShippingProfileField(
                      label: s.phoneNumber,
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                    ),
                    ShippingProfileField(
                      label: s.landlinePhone,
                      controller: _landline,
                      keyboardType: TextInputType.phone,
                    ),
                    ShippingProfileField(
                      label: s.website,
                      controller: _website,
                      keyboardType: TextInputType.url,
                    ),
                    ShippingProfileField(
                      label: s.commercialRegister,
                      controller: _commercialRegister,
                    ),
                    ShippingProfileField(
                      label: s.taxNumber,
                      controller: _taxNumber,
                    ),
                    ShippingInfoBox(message: s.shippingProfileReviewNote),
                    SizedBox(height: 20.h),
                    ShippingPrimaryButton(
                      label: s.saveChanges,
                      loading: loading,
                      onPressed: isDeletingAccount ? null : _save,
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: isDeletingAccount
                          ? null
                          : () => context.push(AppRoutes.kChangePasswordView),
                      child: Text(
                        s.changePassword,
                        style: TextStyle(
                          color: LightColor.defaultColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          isDeletingAccount ? null : _confirmDeleteAccount,
                      child: Text(
                        s.deleteAccount,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: isDeletingAccount ? null : _logout,
                      child: Text(
                        s.logout,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeletingAccount)
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
