import 'dart:io';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ShippingCompletRegisterView extends StatefulWidget {
  const ShippingCompletRegisterView({
    super.key,
    required this.registrationData,
  });

  final Map<String, dynamic> registrationData;

  @override
  State<ShippingCompletRegisterView> createState() =>
      _ShippingCompletRegisterViewState();
}

class _ShippingCompletRegisterViewState
    extends State<ShippingCompletRegisterView> {
  final ImagePicker _picker = ImagePicker();
  String? _tradeLicenseFile;
  final List<String> _companySiteImages = [];

  Future<ImageSource?> _pickImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(S.of(context).gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(S.of(context).camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTradeLicense() async {
    final source = await _pickImageSource();
    if (source == null) return;
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;
    if (!mounted) return;
    setState(() => _tradeLicenseFile = image.path);
  }

  Future<void> _pickCompanySiteImages() async {
    final source = await _pickImageSource();
    if (source == null) return;
    List<String> selectedPaths = [];
    if (source == ImageSource.gallery) {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      selectedPaths = images.map((image) => image.path).toList();
    } else {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;
      selectedPaths = [image.path];
    }
    if (!mounted) return;
    setState(() => _companySiteImages.addAll(selectedPaths));
  }

  Future<void> _onConfirm() async {
    if (_tradeLicenseFile == null) {
      AppToast.showError(
        context,
        S.of(context).tradeLicenseNumberIsRequired,
      );
      return;
    }

    final cubit = AuthCubit.get(context);
    final uploadedLicencePath =
        await cubit.uploadCompanyLicence(_tradeLicenseFile!);
    if (uploadedLicencePath == null || uploadedLicencePath.isEmpty) {
      if (!mounted) return;
      AppToast.showError(context, S.of(context).accountCreationFailed);
      return;
    }

    final List<String> companyImagePaths = [];
    for (final imagePath in _companySiteImages) {
      final uploadedCompanyImagePath =
          await cubit.uploadCompanyImages(imagePath);
      if (uploadedCompanyImagePath == null ||
          uploadedCompanyImagePath.isEmpty) {
        if (!mounted) return;
        AppToast.showError(context, S.of(context).accountCreationFailed);
        return;
      }
      companyImagePaths.add(uploadedCompanyImagePath);
    }

    final data = widget.registrationData;
    final companyName = data['companyName']?.toString() ?? '';
    cubit.registerCompany(
      fullName: companyName,
      companyName: companyName,
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      licenseNumber: data['licenseNumber']?.toString() ?? '',
      licencePath: uploadedLicencePath,
      companyImagePaths: companyImagePaths,
      commercialRegister: data['address']?.toString() ?? '',
      isCustomerCompany: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final companyName = widget.registrationData['companyName']?.toString() ?? '';

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffF2F7FF),
        body: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is RegisterSellerSuccessState) {
              AuthService.instance.setCompanyWaiting(true);
              AppToast.showSuccess(context, s.accountCreatedSuccessfully);
              context.push(
                AppRoutes.kOtpVerificationView,
                extra: {
                  'email': widget.registrationData['email']?.toString() ?? '',
                  'isShippingCompany': true,
                },
              );
            } else if (state is RegisterSellerErrorState) {
              AppToast.showError(context, state.message);
            } else if (state is UploadFileErrorState) {
              AppToast.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is RegisterSellerLoadingState ||
                state is UploadFileLoadingState;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(),
                  SizedBox(height: 16.h),
                  Text(
                    s.completeShippingCompanyRegistration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    companyName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: LightColor.defaultColor,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _UploadSection(
                    title: s.uploadTradeLicense,
                    subtitle: s.dragDropOrTapToUpload,
                    filePath: _tradeLicenseFile,
                    onTap: isLoading ? null : _pickTradeLicense,
                  ),
                  SizedBox(height: 16.h),
                  _UploadSection(
                    title: s.uploadCompanySiteImages,
                    subtitle: s.pdfJpgPngMax10Mb,
                    filePaths: _companySiteImages,
                    onTap: isLoading ? null : _pickCompanySiteImages,
                  ),
                  SizedBox(height: 28.h),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          text: s.confirm,
                          onPressed: _onConfirm,
                          backgroundColor: LightColor.defaultColor,
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UploadSection extends StatelessWidget {
  const _UploadSection({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filePath,
    this.filePaths = const [],
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? filePath;
  final List<String> filePaths;

  @override
  Widget build(BuildContext context) {
    final hasFile = filePath != null || filePaths.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: hasFile ? LightColor.defaultColor : const Color(0xffE0E0E0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(AppAssets.uploadIcon, width: 24.w),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasFile)
                  Icon(Icons.check_circle, color: LightColor.defaultColor),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: LightColor.greyTextColor,
              ),
            ),
            if (filePath != null) ...[
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  File(filePath!),
                  height: 100.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (filePaths.isNotEmpty) ...[
              SizedBox(height: 10.h),
              SizedBox(
                height: 80.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filePaths.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(
                      File(filePaths[index]),
                      width: 80.w,
                      height: 80.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
