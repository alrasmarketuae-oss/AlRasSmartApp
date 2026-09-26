import 'dart:io';

import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/data/models/registration_completion_request_model.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/add_address_dialog.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CompleteRegistrationView extends StatefulWidget {
  const CompleteRegistrationView({super.key, this.initialRequest});

  final RegistrationCompletionRequestModel? initialRequest;

  @override
  State<CompleteRegistrationView> createState() =>
      _CompleteRegistrationViewState();
}

class _CompleteRegistrationViewState extends State<CompleteRegistrationView> {
  final ImagePicker _picker = ImagePicker();
  late RegistrationCompletionRequestModel _request;
  bool _submitting = false;
  bool _addressDone = false;
  bool _documentsDone = false;
  bool _imagesDone = false;
  String? _tradeLicensePath;
  final List<String> _companyImagePaths = [];

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest ??
        const RegistrationCompletionRequestModel(
          missingLocation: true,
          missingImages: true,
          missingDocuments: true,
        );
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  String get _userMessage {
    final custom = _request.userMessage ?? _request.message;
    if (custom != null && custom.trim().isNotEmpty) return custom.trim();
    return _isAr
        ? 'يوجد بيانات ناقصة في تسجيلك. أكمل الخطوات ثم أعد الإرسال للمراجعة.'
        : 'Your registration is missing details. Complete the steps, then resubmit for review.';
  }

  Future<ImageSource?> _pickImageSource() => showImageSourceSheet(context);

  Future<void> _pickAddress() async {
    final result = await showDialog<CreateAddressRequest>(
      context: context,
      builder: (_) => const AddAddressDialog(collectOnly: true),
    );
    if (result == null) return;

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      AppToast.showInfo(
        context,
        _isAr
            ? 'سجّل الدخول أولاً لإكمال البيانات.'
            : 'Please sign in again to complete registration.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.addressesEndPoint,
        token: token,
        data: result.toJson(),
      );
      if (response?.statusCode != 200 && response?.statusCode != 201) {
        throw Exception(
          response?.data is Map
              ? response?.data['message']?.toString()
              : 'Failed to save address',
        );
      }
      if (!mounted) return;
      setState(() {
        _addressDone = true;
        _submitting = false;
      });
      AppToast.showInfo(
        context,
        _isAr ? 'تم حفظ الموقع.' : 'Location saved.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.showInfo(context, e.toString());
    }
  }

  Future<void> _pickTradeLicense() async {
    final source = await _pickImageSource();
    if (source == null) return;
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    setState(() {
      _tradeLicensePath = image.path;
      _submitting = true;
    });
    try {
      await ProfileService.instance.uploadMyCompanyLicence(image.path);
      if (!mounted) return;
      setState(() {
        _documentsDone = true;
        _submitting = false;
      });
      AppToast.showInfo(
        context,
        _isAr ? 'تم رفع الرخصة.' : 'Licence uploaded.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.showInfo(context, e.toString());
    }
  }

  Future<void> _pickCompanyImages() async {
    final source = await _pickImageSource();
    if (source == null) return;
    final List<String> selected = [];
    if (source == ImageSource.gallery) {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      selected.addAll(images.map((e) => e.path));
    } else {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) selected.add(image.path);
    }
    if (selected.isEmpty) return;

    setState(() {
      _companyImagePaths.addAll(selected);
      _submitting = true;
    });
    try {
      for (final path in selected) {
        await ProfileService.instance.uploadMyCompanyImage(path);
      }
      if (!mounted) return;
      setState(() {
        _imagesDone = true;
        _submitting = false;
      });
      AppToast.showInfo(
        context,
        _isAr ? 'تم رفع صور الشركة.' : 'Company images uploaded.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.showInfo(context, e.toString());
    }
  }

  Future<void> _resubmit() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      AppToast.showInfo(
        context,
        _isAr
            ? 'سجّل الدخول أولاً لإكمال البيانات.'
            : 'Please sign in again to complete registration.',
      );
      return;
    }

    if (_request.missingLocation && !_addressDone) {
      AppToast.showInfo(
        context,
        _isAr ? 'حدّد الموقع أولاً.' : 'Please set your location first.',
      );
      return;
    }
    if (_request.missingDocuments && !_documentsDone) {
      AppToast.showInfo(
        context,
        _isAr ? 'ارفع الرخصة أولاً.' : 'Please upload the licence first.',
      );
      return;
    }
    if (_request.missingImages && !_imagesDone) {
      AppToast.showInfo(
        context,
        _isAr ? 'ارفع صور الشركة أولاً.' : 'Please upload company images first.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.resubmitRegistrationEndPoint,
        token: token,
        data: {},
      );
      if (response?.statusCode != 200) {
        throw Exception(
          response?.data is Map
              ? response?.data['message']?.toString()
              : 'Failed to resubmit',
        );
      }
      if (!mounted) return;
      AppToast.showInfo(
        context,
        response?.data is Map
            ? (response?.data['message']?.toString() ??
                (_isAr
                    ? 'تم إعادة الإرسال للمراجعة.'
                    : 'Resubmitted for review.'))
            : (_isAr
                ? 'تم إعادة الإرسال للمراجعة.'
                : 'Resubmitted for review.'),
      );
      context.go(AppRoutes.kUnderReviewView);
    } catch (e) {
      if (!mounted) return;
      AppToast.showInfo(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              const AuthHeader(),
              SizedBox(height: 20.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _isAr ? 'استكمال بيانات التسجيل' : 'Complete registration',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _userMessage,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xCC333333),
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: ListView(
                  children: [
                    if (_request.missingLocation)
                      _StepCard(
                        title: _isAr ? 'الموقع / العنوان' : 'Location / Address',
                        done: _addressDone,
                        subtitle: _addressDone
                            ? (_isAr ? 'تم الحفظ' : 'Saved')
                            : (_isAr
                                ? 'اضغط لتحديد الموقع من الخريطة'
                                : 'Tap to pick location on the map'),
                        onTap: _submitting ? null : _pickAddress,
                      ),
                    if (_request.missingDocuments)
                      _StepCard(
                        title: _isAr ? 'الرخصة / المستندات' : 'Licence / Documents',
                        done: _documentsDone,
                        subtitle: _tradeLicensePath == null
                            ? (_isAr
                                ? 'ارفع صورة الرخصة التجارية'
                                : 'Upload trade licence photo')
                            : File(_tradeLicensePath!).path.split(RegExp(r'[\\/]')).last,
                        onTap: _submitting ? null : _pickTradeLicense,
                        previewPath: _tradeLicensePath,
                      ),
                    if (_request.missingImages)
                      _StepCard(
                        title: _isAr ? 'صور الشركة' : 'Company images',
                        done: _imagesDone,
                        subtitle: _companyImagePaths.isEmpty
                            ? (_isAr
                                ? 'ارفع صور موقع الشركة'
                                : 'Upload company site photos')
                            : (_isAr
                                ? '${_companyImagePaths.length} صور'
                                : '${_companyImagePaths.length} photos'),
                        onTap: _submitting ? null : _pickCompanyImages,
                      ),
                  ],
                ),
              ),
              PrimaryButton(
                text: _submitting
                    ? (_isAr ? 'جاري الإرسال...' : 'Submitting...')
                    : (_isAr ? 'إعادة الإرسال للمراجعة' : 'Resubmit for review'),
                onPressed: _submitting ? null : _resubmit,
                width: double.infinity,
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => context.go(AppRoutes.kUnderReviewView),
                child: Text(s.underReview),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
    this.previewPath,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onTap;
  final String? previewPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: done ? const Color(0xFFE8F5E9) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                if (previewPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(
                      File(previewPath!),
                      width: 48.w,
                      height: 48.w,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  CircleAvatar(
                    backgroundColor: done
                        ? const Color(0xFF619D50)
                        : LightColor.defaultColor,
                    child: Icon(
                      done ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
