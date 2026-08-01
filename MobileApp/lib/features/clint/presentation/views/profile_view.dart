import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/profile_avatar.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/delete_account_dialog.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _roleLabel = '';
  bool _loading = true;
  String? _imgPath;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final bio = BiometricAuthService.instance;
    final supported =
        await bio.isDeviceSupported && await bio.hasEnrolledBiometrics;
    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = bio.isEnabled;
    });
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (_biometricBusy) return;
    final s = S.of(context);
    setState(() => _biometricBusy = true);

    try {
      if (enable) {
        final supported = await BiometricAuthService.instance.isDeviceSupported;
        final enrolled =
            await BiometricAuthService.instance.hasEnrolledBiometrics;
        if (!supported) {
          if (mounted) AppToast.showError(context, s.biometricNotAvailable);
          return;
        }
        if (!enrolled) {
          if (mounted) AppToast.showError(context, s.biometricNoEnrolled);
          return;
        }
        final ok = await BiometricAuthService.instance.enableForCurrentSession(
          reason: s.biometricEnableReason,
        );
        if (!mounted) return;
        if (ok) {
          setState(() => _biometricEnabled = true);
          AppToast.showSuccess(context, s.biometricEnabledSuccess);
        }
      } else {
        await BiometricAuthService.instance.disable();
        if (!mounted) return;
        setState(() => _biometricEnabled = false);
        AppToast.showSuccess(context, s.biometricDisabledSuccess);
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _loadProfile() async {
    final auth = AuthService.instance;
    setState(() {
      _name = auth.currentUserName ?? '';
      _email = auth.currentUserEmail ?? '';
      _phone = auth.currentUserPhone ?? '';
      _roleLabel = auth.currentUserRoleName ?? '';
      _imgPath = auth.currentUserImagePath;
    });

    try {
      final profile =
          await ProfileService.instance.fetchMyProfile(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _name = profile.fullName;
        _email = profile.email;
        _phone = profile.phoneNumber ?? '';
        _roleLabel = profile.roleName.isNotEmpty
            ? profile.roleName
            : (profile.isCompanyAccount
                ? (AuthService.instance.currentUserIsCustomer
                    ? S.of(context).companyCustomerAccount
                    : S.of(context).supplierAccount)
                : S.of(context).personalAccount);
        _imgPath = profile.imgPath;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final authRole = AuthService.instance;
      setState(() {
        _roleLabel = authRole.isCompanyCustomerAccount
            ? S.of(context).companyCustomerAccount
            : authRole.isSupplierAccount
                ? S.of(context).supplierAccount
                : authRole.isPersonalCustomerAccount
                    ? S.of(context).personalAccount
                    : (auth.currentUserRoleName ?? S.of(context).account);
        _loading = false;
      });
    }
  }

  String get _avatarInitial {
    final source = _name.trim().isNotEmpty ? _name : _email;
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }

  Widget _biometricToggleItem() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: LightColor.defaultColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).enableBiometricUnlock,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  S.of(context).biometricUnlockSubtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (_biometricBusy)
            SizedBox(
              width: 22.w,
              height: 22.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
              activeThumbColor: LightColor.defaultColor,
            ),
        ],
      ),
    );
  }

  Widget _accountItem(
    String title,
    String? iconPath, {
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
    bool isArrow = true,
    int badgeCount = 0,
  }) {
    assert(icon != null || iconPath != null);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.white,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color ?? LightColor.defaultColor,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: icon != null
                        ? Icon(icon, color: Colors.white, size: 22.sp)
                        : SvgPicture.asset(
                            iconPath!,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
                if (badgeCount > 0) ...[
                  SizedBox(width: 8.w),
                  Container(
                    constraints: BoxConstraints(minWidth: 20.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (isArrow)
              Icon(
                Icons.chevron_right_rounded,
                size: 28.sp,
                color: LightColor.defaultColor,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final password = await DeleteAccountDialog.show(context);
    if (!mounted || password == null || password.isEmpty) return;
    await context.read<AuthCubit>().deleteAccount(password: password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthStates>(
      listenWhen: (_, current) =>
          current is DeleteAccountSuccessState ||
          current is DeleteAccountErrorState,
      listener: (context, state) async {
        if (state is DeleteAccountErrorState) {
          AppToast.showError(context, state.message);
          return;
        }

        if (state is DeleteAccountSuccessState) {
          AppToast.showSuccess(context, state.message);
          if (!context.mounted) return;
          context.read<ClintCubit>().setTab(0);
          context.read<CompanyCubit>().setTab(0);
          context.go(AppRoutes.kLoginView);
        }
      },
      child: BlocBuilder<ClintCubit, ClintStates>(
        builder: (context, state) {
          final isDeletingAccount =
              context.watch<AuthCubit>().state is DeleteAccountLoadingState;

          return Stack(
            children: [
              Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SearchHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              SizedBox(height: 8.h),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.15),
                                      offset: Offset(0, 0),
                                      blurRadius: 2,
                                    ),
                                  ],
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                _loading ? '...' : _name,
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.5,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                _roleLabel,
                                                style: TextStyle(
                                                  color: LightColor
                                                      .greyTextColor60,
                                                  fontSize: 14.sp,
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.normal,
                                                  height: 1.5,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                _email,
                                                style: TextStyle(
                                                  color: LightColor
                                                      .greyTextColor60,
                                                  fontSize: 14.sp,
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.normal,
                                                  height: 1.5,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                _phone.isNotEmpty
                                                    ? _phone
                                                    : '—',
                                                style: TextStyle(
                                                  color: LightColor
                                                      .greyTextColor60,
                                                  fontSize: 14.sp,
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.normal,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        ProfileAvatar(
                                          size: 56.w,
                                          imagePath: _imgPath,
                                          fallbackText: _avatarInitial,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 40.h,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Color(0xffF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                        ),
                                        onPressed: () async {
                                          await context.push(
                                            AppRoutes.kEditProfileView,
                                          );
                                          if (!mounted) return;
                                          await _loadProfile();
                                        },
                                        child: Text(
                                          S.of(context).editProfile,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14.sp,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.bold,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),
                              _accountItem(
                                S.of(context).aiAssistantTitle,
                                null,
                                icon: Icons.auto_awesome_rounded,
                                onTap: () {
                                  if (AppRoutes.shouldSkipPush(
                                    context,
                                    AppRoutes.kAiAssistantView,
                                  )) {
                                    return;
                                  }
                                  context.push(AppRoutes.kAiAssistantView);
                                },
                              ),
                              SizedBox(height: 13.h),
                              _accountItem(
                                S.of(context).liveChat,
                                AppAssets.profileMessageIcon,
                                onTap: () {
                                  context.push(AppRoutes.kSupportChatView);
                                },
                              ),
                              SizedBox(height: 20.h),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    S.of(context).account,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.sp,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).cart,
                                    AppAssets.profileLockAltFillIcon,
                                    onTap: () {
                                      context.push(AppRoutes.kCartView);
                                    },
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).personalInformation,
                                    AppAssets.blueProfileIcon,
                                    onTap: () async {
                                      await context.push(
                                        AppRoutes.kEditProfileView,
                                      );
                                      if (!mounted) return;
                                      await _loadProfile();
                                    },
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).changePassword,
                                    AppAssets.profileLockAltFillIcon,
                                    onTap: () {
                                      context.push(
                                        AppRoutes.kChangePasswordView,
                                      );
                                    },
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).savedAddresses,
                                    AppAssets.profileLocationIcon,
                                    onTap: () {
                                      context.push(
                                        AppRoutes.kSavedAddressesView,
                                      );
                                    },
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).savedAds,
                                    AppAssets.profileAdsIcon,
                                    onTap: () {
                                      context.push(AppRoutes.kSavedAdsView);
                                    },
                                  ),
                                  if (AuthService
                                      .instance
                                      .isSupplierAccount) ...[
                                    SizedBox(height: 13.h),
                                    _accountItem(
                                      S.of(context).myBalance,
                                      AppAssets.profileBadgePercentIcon,
                                      onTap: () {
                                        context.push(
                                          AppRoutes.kSupplierBalanceView,
                                        );
                                      },
                                    ),
                                    SizedBox(height: 13.h),
                                    _accountItem(
                                      S.of(context).myAds,
                                      AppAssets.profileAdsIcon,
                                      onTap: () {
                                        context.push(AppRoutes.kMyAdsView);
                                      },
                                    ),
                                  ] else if (AuthService
                                      .instance
                                      .currentUserIsCompanyAccount) ...[
                                    SizedBox(height: 13.h),
                                    _accountItem(
                                      S.of(context).myAds,
                                      AppAssets.profileAdsIcon,
                                      onTap: () {
                                        context.push(AppRoutes.kMyAdsView);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 20.h),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    S.of(context).settings,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.sp,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).language,
                                    AppAssets.profileLanguageIcon,
                                    onTap: () {
                                      context.push(AppRoutes.kLanguageView);
                                    },
                                  ),
                                  if (_biometricSupported) ...[
                                    SizedBox(height: 13.h),
                                    _biometricToggleItem(),
                                  ],
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    onTap: () {
                                      context.push(
                                        AppRoutes.kTechnicalSupportView,
                                      );
                                    },
                                    S.of(context).helpSupport,
                                    AppAssets.profileHelpSupportIcon,
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).policyAndPrivacy,
                                    AppAssets.profilePrivacyPolicyIcon,
                                    onTap: () {
                                      context.push(
                                        AppRoutes.kTermsAndConditions,
                                      );
                                    },
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).deleteAccount,
                                    AppAssets.profileLogOutIcon,
                                    color: LightColor.defultRed,
                                    onTap: isDeletingAccount
                                        ? null
                                        : _confirmDeleteAccount,
                                    isArrow: false,
                                  ),
                                  SizedBox(height: 13.h),
                                  _accountItem(
                                    S.of(context).logOut,
                                    AppAssets.profileLogOutIcon,
                                    color: LightColor.defultRed,
                                    onTap: () async {
                                      await AuthService.instance.logout();
                                      if (!context.mounted) return;
                                      context.read<ClintCubit>().setTab(0);
                                      context.read<CompanyCubit>().setTab(0);
                                      context.go(AppRoutes.kLoginView);
                                    },
                                    isArrow: false,
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
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
