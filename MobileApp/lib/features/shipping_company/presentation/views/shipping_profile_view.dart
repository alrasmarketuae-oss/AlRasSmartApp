import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
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
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _commercialRegister = TextEditingController();
  final _taxNumber = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _companyName.dispose();
    _email.dispose();
    _phone.dispose();
    _commercialRegister.dispose();
    _taxNumber.dispose();
    super.dispose();
  }

  void _fillFromDashboard(ShippingCompanyLoadedState state) {
    if (_initialized) return;
    _companyName.text = state.dashboard.companyName;
    _email.text = state.dashboard.email;
    _phone.text = state.dashboard.phoneNumber;
    _commercialRegister.text = state.dashboard.commercialRegister;
    _taxNumber.text = state.dashboard.taxNumber;
    _initialized = true;
  }

  Future<void> _save() async {
    final s = S.of(context);
    final ok = await context.read<ShippingCompanyCubit>().saveProfile(
          companyName: _companyName.text.trim(),
          phoneNumber: _phone.text.trim(),
          commercialRegister: _commercialRegister.text.trim(),
          taxNumber: _taxNumber.text.trim(),
        );
    if (ok && mounted) {
      AppToast.showSuccess(context, s.savedSuccessfully);
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    context.go(AppRoutes.kLoginView);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return BlocBuilder<ShippingCompanyCubit, ShippingCompanyStates>(
      builder: (context, state) {
        final dashboard = state is ShippingCompanyLoadedState
            ? state.dashboard
            : context.read<ShippingCompanyCubit>().dashboard;

        if (state is ShippingCompanyLoadedState) {
          _fillFromDashboard(state);
        } else if (!_initialized && dashboard != null) {
          _companyName.text = dashboard.companyName;
          _email.text = dashboard.email;
          _phone.text = dashboard.phoneNumber;
          _commercialRegister.text = dashboard.commercialRegister;
          _taxNumber.text = dashboard.taxNumber;
          _initialized = true;
        }

        final stats = dashboard?.stats;
        final loading = state is ShippingCompanyActionLoadingState;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
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
                onPressed: _save,
              ),
              SizedBox(height: 24.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  s.settings,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              ShippingSettingsTile(
                icon: Icons.language_outlined,
                label: s.language,
                onTap: () => context.push(AppRoutes.kLanguageView),
              ),
              SizedBox(height: 10.h),
              ShippingSettingsTile(
                icon: Icons.logout,
                label: s.logOut,
                isDestructive: true,
                onTap: _logout,
              ),
            ],
          ),
        );
      },
    );
  }
}
