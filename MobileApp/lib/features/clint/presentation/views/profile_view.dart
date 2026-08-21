import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/widgets/login_required_sheet.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/services/sensitive_access_gate.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/theme/colors.dart';
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

const Color _kSubtitleColor = Color(0xFF7B8794);
const Color _kBlue = Color(0xFF2E77CC);
const Color _kBlueDark = Color(0xFF1B5FB8);
const Color _kGreen = Color(0xFF23C08B);
const Color _kGreenDark = Color(0xFF12A874);
const Color _kRed = Color(0xFFF05B54);
const Color _kRedDark = Color(0xFFDE3F38);

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.isTabView = false});

  /// When true, hides back/search (embedded in bottom navigation).
  final bool isTabView;

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

  bool _shouldShowRoleLabel() {
    if (_roleLabel.trim().isEmpty) return false;
    if (AuthService.instance.isSupplierAccount) return false;

    final normalized = _roleLabel.trim().toLowerCase();
    return normalized != 'seller' &&
        normalized != 'supplier' &&
        normalized != 'بائع' &&
        normalized != 'مورد';
  }

  String get _avatarInitial {
    final source = _name.trim().isNotEmpty ? _name : _email;
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _openEditProfile() async {
    await context.push(AppRoutes.kEditProfileView);
    if (!mounted) return;
    await _loadProfile();
  }

  Future<void> _confirmDeleteAccount() async {
    final password = await DeleteAccountDialog.show(context);
    if (!mounted || password == null || password.isEmpty) return;
    await context.read<AuthCubit>().deleteAccount(password: password);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    final clint = context.read<ClintCubit>();
    clint.setTab(0);
    clint.clearHomeCatalogMemory();
    context.read<CompanyCubit>().setTab(0);
    goToGuestHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

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
          goToGuestHome(context);
        }
      },
      child: BlocBuilder<ClintCubit, ClintStates>(
        builder: (context, state) {
          final isDeletingAccount =
              context.watch<AuthCubit>().state is DeleteAccountLoadingState;
          final isSupplier = AuthService.instance.isSupplierAccount;
          final isCompany = AuthService.instance.currentUserIsCompanyAccount;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.scaffold(context),
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SearchHeader(
                      isBackButton: !widget.isTabView,
                      isSearch: !widget.isTabView,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileCard(),
                            SizedBox(height: 14.h),
                            Row(
                            children: [
                                Expanded(
                                  child: _ShortcutCard(
                                    title: s.aiAssistantTitle,
                                    subtitle: s.aiAssistantCardSubtitle,
                                    assetIcon: AppAssets.aiAgentIcon,
                                    onTap: () {
                                      SensitiveAccessGate.openProtectedRoute(
                                        context,
                                        route: AppRoutes.kAiAssistantView,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                        Expanded(
                                  child: _ShortcutCard(
                                    title: s.liveChat,
                                    subtitle: s.liveChatSubtitle,
                                    assetIcon: AppAssets.profileMessageIcon,
                                    onTap: () =>
                                        context.push(AppRoutes.kSupportChatView),
                                                ),
                                              ),
                                            ],
                                          ),
                            SizedBox(height: 22.h),
                            _SectionTitle(s.account),
                            SizedBox(height: 12.h),
                            _SettingsTile(
                              title: s.cart,
                              subtitle: s.cartSubtitle,
                              icon: Icons.shopping_bag_outlined,
                              onTap: () => context.push(AppRoutes.kCartView),
                            ),
                            _SettingsTile(
                              title: s.personalInformation,
                              subtitle: s.personalInformationSubtitle,
                              assetIcon: AppAssets.blueProfileIcon,
                              onTap: _openEditProfile,
                            ),
                            _SettingsTile(
                              title: s.changePassword,
                              subtitle: s.changePasswordSubtitle,
                              assetIcon: AppAssets.profileLockAltFillIcon,
                              onTap: () =>
                                  context.push(AppRoutes.kChangePasswordView),
                            ),
                            _SettingsTile(
                              title: s.savedAddresses,
                              subtitle: s.savedAddressesSubtitle,
                              assetIcon: AppAssets.profileLocationIcon,
                              onTap: () =>
                                  context.push(AppRoutes.kSavedAddressesView),
                            ),
                            _SettingsTile(
                              title: s.savedAds,
                              subtitle: s.savedAdsSubtitle,
                              assetIcon: AppAssets.profileAdsIcon,
                              onTap: () => context.push(AppRoutes.kSavedAdsView),
                            ),
                            if (isSupplier || isCompany)
                              _SettingsTile(
                                title: s.myAds,
                                subtitle: s.myAdsSubtitle,
                                assetIcon: AppAssets.profileAdsIcon,
                                onTap: () => context.push(AppRoutes.kMyAdsView),
                              ),
                            if (isSupplier || isCompany)
                              _SettingsTile(
                                title: AuthService.instance.isCompanyCustomerAccount
                                    ? s.changeTargetPrices
                                    : s.changePrices,
                                subtitle: AuthService.instance.isCompanyCustomerAccount
                                    ? s.changeTargetPricesSubtitle
                                    : s.changePricesSubtitle,
                                icon: Icons.sell_rounded,
                                iconColors: const [
                                  Color(0xFFF59E0B),
                                  Color(0xFFD97706),
                                ],
                                onTap: () =>
                                    context.push(AppRoutes.kChangePricesView),
                              ),
                            SizedBox(height: 6.h),
                            const _DataSafeBanner(),
                            SizedBox(height: 22.h),
                            _SectionTitle(s.settings),
                            SizedBox(height: 12.h),
                            _SettingsTile(
                              title: s.language,
                              subtitle: s.changeLanguageSubtitle,
                              assetIcon: AppAssets.profileLanguageIcon,
                              onTap: () => context.push(AppRoutes.kLanguageView),
                            ),
                            _SettingsTile(
                              title: s.aiAssistantVoiceSetting,
                              subtitle: s.aiAssistantVoiceSettingSubtitle,
                              icon: Icons.record_voice_over_rounded,
                              onTap: () => context.push(
                                AppRoutes.kAiAssistantVoiceSettingsView,
                              ),
                            ),
                            if (_biometricSupported)
                              _SettingsTile(
                                title: s.enableBiometricUnlock,
                                subtitle: s.faceIdFingerprintSubtitle,
                                icon: Icons.fingerprint_rounded,
                                trailing: _biometricBusy
                                    ? SizedBox(
                                        width: 22.w,
                                        height: 22.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Switch.adaptive(
                                        value: _biometricEnabled,
                                        onChanged: _toggleBiometric,
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: _kBlue,
                                      ),
                              ),
                            _SettingsTile(
                              title: s.complaintsSuggestions,
                              subtitle: s.complaintsSuggestionsSubtitle,
                              icon: Icons.feedback_outlined,
                              onTap: () =>
                                  context.push(AppRoutes.kComplaintsSuggestionsView),
                            ),
                            _SettingsTile(
                              title: s.helpSupport,
                              subtitle: s.helpSupportSubtitle,
                             assetIcon: AppAssets.profileHelpSupportIcon,
                              onTap: () =>
                                  context.push(AppRoutes.kTechnicalSupportView),
                            ),
                            _SettingsTile(
                              title: s.policyAndPrivacy,
                              subtitle: s.policyAndPrivacySubtitle,
                              assetIcon: AppAssets.profilePrivacyPolicyIcon,
                              iconColors: const [_kGreen, _kGreenDark],
                              onTap: () =>
                                  context.push(AppRoutes.kTermsAndConditions),
                            ),
                            _SettingsTile(
                              title: s.deleteAccount,
                              subtitle: s.deleteAccountSubtitle,
                              assetIcon: AppAssets.profileTrashIcon,
                              iconColors: const [_kRed, _kRedDark],
                                    onTap: isDeletingAccount
                                        ? null
                                        : _confirmDeleteAccount,
                            ),
                            _SettingsTile(
                              title: s.logOut,
                              subtitle: s.logOutSubtitle,
                              assetIcon: AppAssets.profileLogOutIcon,
                              iconColors: const [_kRed, _kRedDark],
                              onTap: _logout,
                            ),
                          ],
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

  Widget _buildProfileCard() {
    final s = S.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16233A).withValues(alpha: 0.06),
            blurRadius: 18.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loading && _name.isEmpty ? '...' : _name,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title(context),
                        height: 1.3,
                      ),
                    ),
                    if (_shouldShowRoleLabel()) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FC),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _roleLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _kBlue,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    _ContactLine(
                      icon: Icons.mail_outline_rounded,
                      text: _email,
                    ),
                    SizedBox(height: 8.h),
                    _ContactLine(
                      icon: Icons.phone_outlined,
                      text: _phone.isNotEmpty ? _phone : '—',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: _openEditProfile,
                child: SizedBox(
                  width: 72.w,
                  height: 72.w,
                  child: Stack(
                    children: [
                      ProfileAvatar(
                        size: 66.w,
                        imagePath: _imgPath,
                        fallbackText: _avatarInitial,
                      ),
                      PositionedDirectional(
                        bottom: 0,
                        end: 0,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: _kBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 11.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 46.h,
            child: ElevatedButton.icon(
              onPressed: _openEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.edit_outlined, size: 18.sp),
              label: Text(
                s.editProfile,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: _kBlue),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF44526B),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.title(context),
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.assetIcon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Row(
        children: [
          _RoundIcon(icon: icon, assetIcon: assetIcon, size: assetIcon?.endsWith('.png') == true ? 52 : 42),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title(context),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    height: 1.3,
                    color: _kSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
          _Chevron(size: 20.sp),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    this.icon,
    this.assetIcon,
    this.iconColors = const [_kBlue, _kBlueDark],
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final String? assetIcon;
  final List<Color> iconColors;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: _CardShell(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            _RoundIcon(icon: icon, assetIcon: assetIcon, colors: iconColors),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title(context),
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      height: 1.35,
                      color: AppColors.subtitle(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            trailing ?? _Chevron(size: 24.sp),
          ],
        ),
      ),
    );
  }
}

class _DataSafeBanner extends StatelessWidget {
  const _DataSafeBanner();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FE),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 30.sp, color: _kBlue),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.dataSafeTitle,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _kBlueDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  s.dataSafeSubtitle,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    height: 1.35,
                    color: const Color(0xFF6C7C93),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.lock_rounded,
            size: 32.sp,
            color: _kBlue.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14.r);
    return Material(
      color: AppColors.card(context),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16233A).withValues(alpha: 0.05),
                blurRadius: 14.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    this.icon,
    this.assetIcon,
    this.colors = const [_kBlue, _kBlueDark],
    this.size = 46,
  });

  final IconData? icon;
  final String? assetIcon;
  final List<Color> colors;
  final double size;

  bool get _isRasterAsset {
    final path = assetIcon?.toLowerCase() ?? '';
    return path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (_isRasterAsset) {
      return Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.22),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          assetIcon!,
          fit: BoxFit.contain,
        ),
      );
    }

    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.30),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: (size * 0.48).sp)
          : SizedBox(
              width: (size * 0.46).w,
              height: (size * 0.46).w,
              child: SvgPicture.asset(
                assetIcon!,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Icon(
        isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        size: size,
        color: _kBlue,
      ),
    );
  }
}
