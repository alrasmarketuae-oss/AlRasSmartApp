import 'package:alrasmarket/core/constants/country_dial_codes.dart';
import 'package:alrasmarket/core/media/image_compressor.dart';
import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
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
import 'package:file_picker/file_picker.dart';
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
  final _taxController = TextEditingController();
  final _landlineController = TextEditingController();
  final _websiteController = TextEditingController();
  final _licenseController = TextEditingController();
  String _selectedCountryCode = '+971';
  String _selectedLandlineCountryCode = '+971';
  bool _loading = true;
  bool _saving = false;
  bool _isCompany = false;
  bool _uploadingImage = false;
  bool _uploadingLicence = false;
  bool _uploadingCompanyImage = false;
  int? _deletingCompanyImageId;
  bool _hasPendingProfileChanges = false;
  String? _profileImagePath;
  String? _licencePath;
  List<CompanyProfileImage> _companyImages = const [];

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
      _taxController.text = profile.taxNumber ?? '';
      final parsedLand = _splitPhone(profile.landNumber ?? '');
      _selectedLandlineCountryCode = parsedLand.$1;
      _landlineController.text = parsedLand.$2;
      _websiteController.text = profile.website ?? '';
      _licenseController.text = (profile.licenseNumber ?? '').trim();
      _isCompany = profile.isCompanyAccount || profile.isShippingCompanyAccount;
      _profileImagePath = profile.imgPath;
      _licencePath = profile.licencePath;
      _companyImages = List<CompanyProfileImage>.from(profile.companyImages);
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
        if (_isCompany) 'taxNumber': _taxController.text.trim(),
        if (_isCompany)
          'landNumber': _composePhone(
            _selectedLandlineCountryCode,
            _landlineController.text.trim(),
          ),
        if (_isCompany) 'website': _websiteController.text.trim(),
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

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

  bool _isPdfPath(String? path) {
    final lower = (path ?? '').toLowerCase();
    return lower.endsWith('.pdf');
  }

  String _fileNameFromPath(String? path) {
    final value = (path ?? '').trim();
    if (value.isEmpty) return '';
    final parts = value.replaceAll('\\', '/').split('/');
    return parts.isEmpty ? value : parts.last;
  }

  Future<void> _pickAndUploadLicence() async {
    if (_uploadingLicence) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: false,
    );
    if (!mounted) return;
    final path = result?.files.singleOrNull?.path;
    if (path == null || path.isEmpty) return;

    setState(() => _uploadingLicence = true);
    try {
      final updated = await ProfileService.instance.uploadMyCompanyLicence(path);
      if (!mounted) return;
      setState(() {
        _licencePath = updated.licencePath;
        _companyImages = List<CompanyProfileImage>.from(updated.companyImages);
      });
      AppToast.showSuccess(
        context,
        _isArabic ? 'تم تحديث ملف الرخصة' : 'Trade licence updated',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingLicence = false);
    }
  }

  Future<void> _pickAndUploadCompanyImages() async {
    if (_uploadingCompanyImage) return;
    final source = await showImageSourceSheet(context);
    if (!mounted || source == null) return;

    final picker = ImagePicker();
    final List<String> paths = [];
    if (source == ImageSource.gallery) {
      final images = await picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      paths.addAll(images.map((e) => e.path));
    } else {
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;
      paths.add(image.path);
    }
    if (!mounted || paths.isEmpty) return;

    setState(() => _uploadingCompanyImage = true);
    try {
      UserProfile? updated;
      for (final rawPath in paths) {
        final compressed =
            await ImageCompressor.compressIfNeeded(rawPath) ?? rawPath;
        updated =
            await ProfileService.instance.uploadMyCompanyImage(compressed);
      }
      if (!mounted || updated == null) return;
      setState(() {
        _licencePath = updated!.licencePath;
        _companyImages = List<CompanyProfileImage>.from(updated.companyImages);
      });
      AppToast.showSuccess(
        context,
        _isArabic ? 'تم إضافة صور الشركة' : 'Company photos added',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingCompanyImage = false);
    }
  }

  Future<void> _deleteCompanyImage(CompanyProfileImage image) async {
    if (_deletingCompanyImageId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isArabic ? 'حذف الصورة' : 'Delete photo'),
        content: Text(
          _isArabic
              ? 'هل تريد حذف صورة الشركة هذه؟'
              : 'Delete this company site photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingCompanyImageId = image.id);
    try {
      final updated =
          await ProfileService.instance.deleteMyCompanyImage(image.id);
      if (!mounted) return;
      setState(() {
        _licencePath = updated.licencePath;
        _companyImages = List<CompanyProfileImage>.from(updated.companyImages);
      });
      AppToast.showSuccess(
        context,
        _isArabic ? 'تم حذف الصورة' : 'Photo deleted',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deletingCompanyImageId = null);
    }
  }

  Widget _buildLicenceSection() {
    final s = S.of(context);
    final url = ApiConstants.resolveMediaUrl(_licencePath);
    final hasLicence = (_licencePath ?? '').trim().isNotEmpty;
    final isPdf = _isPdfPath(_licencePath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.uploadTradeLicense,
          style: TextStyle(
            color: const Color.fromRGBO(51, 51, 51, 1),
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: _uploadingLicence ? null : _pickAndUploadLicence,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE8EDF4)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 2,
                ),
              ],
            ),
            child: _uploadingLicence
                ? SizedBox(
                    height: 90.h,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : hasLicence
                    ? Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: isPdf || url.isEmpty
                                ? Container(
                                    width: 72.w,
                                    height: 72.h,
                                    color: const Color(0xFFF5F5F5),
                                    child: Icon(
                                      Icons.picture_as_pdf,
                                      color: LightColor.defaultColor,
                                      size: 32.sp,
                                    ),
                                  )
                                : CachedAppImage(
                                    key: ValueKey(url),
                                    imageUrl: url,
                                    width: 72.w,
                                    height: 72.h,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      width: 72.w,
                                      height: 72.h,
                                      color: const Color(0xFFF5F5F5),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: LightColor.defaultColor,
                                        size: 28.sp,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileNameFromPath(_licencePath),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  _isArabic
                                      ? 'اضغط لاستبدال الملف (يُحذف القديم)'
                                      : 'Tap to replace (old file is deleted)',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: LightColor.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.upload_file_outlined,
                            color: LightColor.defaultColor,
                            size: 22.sp,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          SvgPicture.asset(
                            AppAssets.uploadIcon,
                            width: 24.w,
                            height: 24.h,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            s.dragDropOrTapToUpload,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A4A4A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            s.pdfJpgPngMax10Mb,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: LightColor.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyImagesSection() {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.uploadCompanySiteImages,
              style: TextStyle(
                color: const Color.fromRGBO(51, 51, 51, 1),
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
            ),
            Text(
              s.optional,
              style: TextStyle(
                fontSize: 14.sp,
                color: LightColor.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_companyImages.isNotEmpty) ...[
          SizedBox(
            height: 110.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _companyImages.length,
              separatorBuilder: (_, _) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final image = _companyImages[index];
                final url = ApiConstants.resolveMediaUrl(image.imagePath);
                final deleting = _deletingCompanyImageId == image.id;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: CachedAppImage(
                        key: ValueKey('${image.id}-$url'),
                        imageUrl: url,
                        width: 110.w,
                        height: 110.h,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 110.w,
                          height: 110.h,
                          color: const Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: LightColor.hintColor,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: InkWell(
                        onTap: deleting ? null : () => _deleteCompanyImage(image),
                        child: Container(
                          width: 28.w,
                          height: 28.h,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Center(
                            child: deleting
                                ? SizedBox(
                                    width: 12.w,
                                    height: 12.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
        InkWell(
          onTap: _uploadingCompanyImage ? null : _pickAndUploadCompanyImages,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE8EDF4)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 2,
                ),
              ],
            ),
            child: _uploadingCompanyImage
                ? SizedBox(
                    height: 48.h,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      SvgPicture.asset(
                        AppAssets.uploadIcon,
                        width: 24.w,
                        height: 24.h,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        s.dragDropOrTapToUpload,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A4A4A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _isArabic
                            ? 'إضافة صور جديدة أو حذف الحالية'
                            : 'Add new photos or remove existing ones',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: LightColor.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
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
      builder: (context, _, _) {
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

  Widget _buildLandlineRow() {
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
                  s.landlinePhone,
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
                  value: _selectedLandlineCountryCode,
                  onChanged: (value) {
                    setState(() => _selectedLandlineCountryCode = value);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 3,
                child: CustomTextFormField(
                  controller: _landlineController,
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
    _taxController.dispose();
    _landlineController.dispose();
    _websiteController.dispose();
    _licenseController.dispose();
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
                              label: S.of(context).tradeLicenseNumber,
                              controller: _licenseController,
                              readOnly: true,
                            ),
                            SizedBox(height: 20.h),
                            _profileField(
                              label: S.of(context).taxNumber,
                              controller: _taxController,
                            ),
                            SizedBox(height: 20.h),
                            _buildLandlineRow(),
                            SizedBox(height: 20.h),
                            _profileField(
                              label: S.of(context).website,
                              controller: _websiteController,
                            ),
                            SizedBox(height: 20.h),
                            _buildLicenceSection(),
                            SizedBox(height: 20.h),
                            _buildCompanyImagesSection(),
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
                                      ? 'حسابك تحت المراجعة حاليًا للتعديلات المرسلة. يمكنك متابعة استخدام التطبيق والبيانات الحالية حتى موافقة الأدمن. تحديث الرخصة وصور الشركة يُطبَّق فورًا.'
                                      : 'ملاحظة: عند الضغط على تحديث، ستُراجع بيانات النص من الأدمن. تحديث ملف الرخصة وصور الشركة يُطبَّق فورًا ويحذف الملفات السابقة.')
                                  : (_hasPendingProfileChanges
                                      ? 'Your account changes are under review. You can keep using the app with the current data until admin approval. Licence and company photos update immediately.'
                                      : 'Note: pressing update sends text changes for admin review. Licence file and company photos update immediately and replace previous files.'),
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
