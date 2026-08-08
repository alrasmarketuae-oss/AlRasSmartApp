import 'package:alrasmarket/core/constants/country_dial_codes.dart';
import 'package:alrasmarket/core/media/image_compressor.dart';
import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/profile_image_url.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/features/auth/presentation/views/widgets/contry_code.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/cubit/clint_cubit.dart';
import '../../controller/cubit/clint_states.dart';
import '../../widgets/search_header.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _commercialController = TextEditingController();
  final _taxController = TextEditingController();
  String _selectedCountryCode = '+971';
  bool _loading = true;
  bool _saving = false;
  bool _isCompany = false;
  bool _uploadingImage = false;
  bool _hasPendingProfileChanges = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = AuthService.instance;
    _nameController.text = auth.currentUserName ?? '';
    _emailController.text = auth.currentUserEmail ?? '';
    _phoneController.text = auth.currentUserPhone ?? '';
    _isCompany = auth.currentUserIsCompanyAccount;
    _profileImagePath = auth.currentUserImagePath;

    try {
      final profile = await ProfileService.instance.fetchMyProfile(forceRefresh: true);
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      final parsedPhone = _splitPhone(profile.phoneNumber ?? '');
      _selectedCountryCode = parsedPhone.$1;
      _phoneController.text = parsedPhone.$2;
      _companyController.text = profile.companyName ?? '';
      _commercialController.text = profile.commercialRegister ?? '';
      _taxController.text = profile.taxNumber ?? '';
      _isCompany = profile.isCompanyAccount;
      _profileImagePath = profile.imgPath;
      _hasPendingProfileChanges = profile.hasPendingProfileChanges;
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final fullPhone = _composePhone(
        _selectedCountryCode,
        _phoneController.text.trim(),
      );
      final updated = await ProfileService.instance.updateMyProfile({
        'fullName': _nameController.text.trim(),
        'phoneNumber': fullPhone,
        if (_isCompany) 'companyName': _companyController.text.trim(),
        if (_isCompany) 'commercialRegister': _commercialController.text.trim(),
        if (_isCompany) 'taxNumber': _taxController.text.trim(),
      });
      if (!mounted) return;
      final isAr =
          Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
      if (updated.hasPendingProfileChanges) {
        setState(() => _hasPendingProfileChanges = true);
        AppToast.showSuccess(
          context,
          isAr
              ? 'تم إرسال التعديلات للمراجعة. يمكنك متابعة العمل بالبيانات الحالية.'
              : 'Changes submitted for review. You can keep using the current data.',
        );
      } else {
        setState(() => _hasPendingProfileChanges = false);
        AppToast.showSuccess(
          context,
          isAr ? 'لا توجد تغييرات جديدة.' : 'No new changes to submit.',
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadingImage) return;
    setState(() => _uploadingImage = true);
    try {
      final source = await showImageSourceSheet(context);
      if (!mounted) return;
      if (source == null) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted) return;
      if (picked == null) return;

      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop image',
              toolbarColor: const Color(0xFF4084C1),
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
              initAspectRatio: CropAspectRatioPreset.square,
              hideBottomControls: false,
              activeControlsWidgetColor: const Color(0xFF4084C1),
            ),
            IOSUiSettings(
              title: 'Crop image',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
      } catch (_) {
        if (!mounted) return;
        AppToast.showError(context, 'Could not open image cropper');
        return;
      }

      if (!mounted) return;
      if (cropped == null) return;

      final compressed =
          await ImageCompressor.compressIfNeeded(cropped.path) ?? cropped.path;
      final updated = await ProfileService.instance.uploadMyProfileImage(
        compressed,
      );
      if (!mounted) return;
      setState(() {
        _profileImagePath = updated.imgPath;
      });
      AppToast.showSuccess(context, 'Profile image updated');
      await ProfileService.instance.fetchMyProfile(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  (String, String) _splitPhone(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return (_selectedCountryCode, '');
    final normalized = value.replaceAll(' ', '');
    if (!normalized.startsWith('+')) return (_selectedCountryCode, value);
    final match = CountryDialCode.all
        .where((c) => normalized.startsWith(c.dialCode))
        .toList()
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    if (match.isEmpty) return (_selectedCountryCode, normalized);
    final dial = match.first.dialCode;
    final local = normalized.substring(dial.length).trim();
    return (dial, local);
  }

  String _composePhone(String dial, String local) {
    final cleanLocal = local.replaceAll(RegExp(r'\s+'), '');
    if (cleanLocal.isEmpty) return '';
    if (cleanLocal.startsWith('+')) return cleanLocal;
    return '$dial $cleanLocal';
  }

  Widget _buildProfileImage() {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.instance.profileImageRevision,
      builder: (context, _, __) {
        final url = profileImageUrlFromPath(_profileImagePath);
        return Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999.r),
            gradient: const LinearGradient(
              begin: Alignment(-0.67, 0.45),
              end: Alignment(-0.23, -0.34),
              colors: [
                Color(0xff4084C1),
                Color(0xff70B667),
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: url != null
              ? CachedAppImage(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: 100.w,
                  height: 100.h,
                  fit: BoxFit.cover,
                  errorWidget: SvgPicture.asset(
                    AppAssets.blueProfileIcon,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    width: 80.w,
                    height: 80.h,
                  ),
                )
              : SvgPicture.asset(
                  AppAssets.blueProfileIcon,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 80.w,
                  height: 80.h,
                ),
        );
      },
    );
  }

  Widget _buildPhoneRow() {
    final s = S.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final labelStyle = TextStyle(
      fontSize: 14.sp,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  s.countryCode,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: labelStyle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 3,
                child: Text(
                  s.phoneNumber,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: CountryCodeField(
                  label: s.countryCode,
                  showLabel: false,
                  value: _selectedCountryCode,
                  enabled: false,
                  onChanged: (value) {
                    setState(() => _selectedCountryCode = value);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 3,
                child: CustomTextFormField(
                  controller: _phoneController,
                  hintText: 'XX XXX XXXX',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _commercialController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Widget _profileField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color.fromRGBO(51, 51, 51, 1),
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                offset: Offset(0, 0),
                blurRadius: 2,
              ),
            ],
            color: Colors.white,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(
              color: const Color.fromRGBO(51, 51, 51, 1),
              fontSize: 14.sp,
              fontWeight: FontWeight.normal,
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
              suffixIconConstraints: BoxConstraints(
                minHeight: 20.h,
                minWidth: 20.w,
              ),
              suffixIcon: Padding(
                padding: EdgeInsetsDirectional.only(start: 8.w),
                child: icon != null
                    ? Icon(icon, size: 24.sp, color: LightColor.defaultColor)
                    : SvgPicture.asset(
                        AppAssets.profileEdit1Icon,
                        width: 16.w,
                        height: 16.h,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Column(
              children: [
                SearchHeader(),
                SizedBox(height: 12.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 100.w,
                            height: 100.h,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: _buildProfileImage(),
                                  ),
                                ),
                                Positioned(
                                  top: 68.h,
                                  left: 68.w,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: Container(
                                      width: 32.w,
                                      height: 32.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999.r,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromRGBO(
                                              0,
                                              0,
                                              0,
                                              0.1,
                                            ),
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color.fromRGBO(
                                            248,
                                            250,
                                            252,
                                            1,
                                          ),
                                          width: 1.6,
                                        ),
                                      ),
                                      child: Center(
                                        child: _uploadingImage
                                            ? SizedBox(
                                                width: 14.w,
                                                height: 14.h,
                                                child:
                                                    const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : SvgPicture.asset(
                                                AppAssets.profileEdit1Icon,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  Color(0xff4084C1),
                                                  BlendMode.srcIn,
                                                ),
                                                width: 16.w,
                                                height: 16.h,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 50.h),

                          _profileField(
                            label: S.of(context).fullName,
                            controller: _nameController,
                          ),
                          SizedBox(height: 20.h),
                          _profileField(
                            label: S.of(context).email,
                            controller: _emailController,
                            readOnly: true,
                          ),
                          SizedBox(height: 20.h),
                          _buildPhoneRow(),

                          if (_isCompany) ...[
                            SizedBox(height: 20.h),
                            _profileField(
                              label: S.of(context).companyName,
                              controller: _companyController,
                            ),
                            SizedBox(height: 20.h),
                            _profileField(
                              label: S.of(context).commercialRegistration,
                              controller: _commercialController,
                            ),
                            SizedBox(height: 20.h),
                            _profileField(
                              label: S.of(context).taxNumber,
                              controller: _taxController,
                            ),
                          ],
                          SizedBox(height: 16.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFAEB),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: const Color(0xFFFEDF89)),
                            ),
                            child: Text(
                              Localizations.localeOf(context)
                                          .languageCode
                                          .toLowerCase() ==
                                      'ar'
                                  ? (_hasPendingProfileChanges
                                      ? 'حسابك تحت المراجعة حاليًا للتعديلات المرسلة. يمكنك متابعة استخدام التطبيق والبيانات الحالية حتى موافقة الأدمن.'
                                      : 'ملاحظة: عند الضغط على تحديث، سيصبح التعديل تحت المراجعة لحين موافقة الأدمن، وستبقى البيانات الحالية فعالة.')
                                  : (_hasPendingProfileChanges
                                      ? 'Your account changes are under review. You can keep using the app with the current data until admin approval.'
                                      : 'Note: pressing update will send changes for admin review. Current data stays active until approval.'),
                              style: TextStyle(
                                fontSize: 13.sp,
                                height: 1.45,
                                color: const Color(0xFFB54708),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: _loading || _saving
                                ? const Center(child: CircularProgressIndicator())
                                : PrimaryButton(
                                    text: S.of(context).saveChanges,
                                    onPressed: _saveProfile,
                                    backgroundColor: LightColor.defaultColor,
                                  ),
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
        );
      },
    );
  }
}
