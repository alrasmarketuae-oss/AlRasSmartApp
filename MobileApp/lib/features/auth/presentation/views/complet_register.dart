import 'dart:io';

import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CompletRegisterView extends StatefulWidget {
  const CompletRegisterView({super.key, required this.registrationData});

  final Map<String, dynamic> registrationData;

  @override
  State<CompletRegisterView> createState() => _CompletRegisterViewState();
}

class _CompletRegisterViewState extends State<CompletRegisterView> {
  final ImagePicker _picker = ImagePicker();
  String? _tradeLicenseFile;
  final List<String> _companySiteImages = [];

  Future<ImageSource?> _pickImageSource() {
    return showImageSourceSheet(context);
  }

  Future<void> _pickTradeLicense() async {
    final source = await _pickImageSource();
    if (source == null) return;
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;
    if (!mounted) return;
    setState(() {
      _tradeLicenseFile = image.path;
    });
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
    setState(() {
      _companySiteImages.addAll(selectedPaths);
    });
  }

  Future<void> _onConfirm() async {
    final cubit = AuthCubit.get(context);

    String licencePath = '';
    if (_tradeLicenseFile != null) {
      final uploadedLicencePath = await cubit.uploadCompanyLicence(
        _tradeLicenseFile!,
      );
      if (uploadedLicencePath == null || uploadedLicencePath.isEmpty) {
        AppToast.showError(context, 'Error uploading trade license');
        return;
      }
      licencePath = uploadedLicencePath;
    }

    final List<String> companyImagePaths = [];
    for (final imagePath in _companySiteImages) {
      final uploadedCompanyImagePath = await cubit.uploadCompanyImages(
        imagePath,
      );
      if (uploadedCompanyImagePath == null ||
          uploadedCompanyImagePath.isEmpty) {
        AppToast.showError(context, ' error uploading company images');
        return;
      }
      companyImagePaths.add(uploadedCompanyImagePath);
    }

    cubit.registerCompany(
      fullName: widget.registrationData['fullName']?.toString() ?? '',
      companyName: widget.registrationData['companyName']?.toString() ?? '',
      email: widget.registrationData['email']?.toString() ?? '',
      password: widget.registrationData['password']?.toString() ?? '',
      phoneNumber: widget.registrationData['phoneNumber']?.toString() ?? '',
      landNumber: widget.registrationData['landNumber']?.toString() ?? '',
      licenseNumber: widget.registrationData['licenseNumber']?.toString() ?? '',
      licencePath: licencePath,
      companyImagePaths: companyImagePaths,

      commercialRegister:
          widget.registrationData['commercialRegister']?.toString() ?? '',
      taxNumber: widget.registrationData['taxNumber']?.toString() ?? '',
      website: widget.registrationData['website']?.toString() ?? '',
      isCustomerCompany: widget.registrationData['isCustomerCompany'] == true ,
    );
  }

  void _registerWithoutFiles() {
    final cubit = AuthCubit.get(context);
    cubit.registerCompany(
      fullName: widget.registrationData['fullName']?.toString() ?? '',
      companyName: widget.registrationData['companyName']?.toString() ?? '',
      email: widget.registrationData['email']?.toString() ?? '',
      password: widget.registrationData['password']?.toString() ?? '',
      phoneNumber: widget.registrationData['phoneNumber']?.toString() ?? '',
      landNumber: widget.registrationData['landNumber']?.toString() ?? '',
      licenseNumber: widget.registrationData['licenseNumber']?.toString() ?? '',
      licencePath: '',
      companyImagePaths: const [],
      isCustomerCompany: widget.registrationData['isCustomerCompany'] == true,
      commercialRegister:
          widget.registrationData['commercialRegister']?.toString() ?? '',
      taxNumber: widget.registrationData['taxNumber']?.toString() ?? '',
      website: widget.registrationData['website']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    print("widget.registrationData.isCustomerCompany: ${widget.registrationData['isCustomerCompany']}");
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      child: Scaffold(
        backgroundColor: LightColor.background,
        body: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is RegisterSellerSuccessState) {
              AuthService.instance.setCompanyWaiting(true);
              AppToast.showSuccess(
                context,
                S.of(context).accountCreatedSuccessfully,
              );
              context.push(
                AppRoutes.kOtpVerificationView,
                extra: {
                  'email': widget.registrationData['email']?.toString() ?? '',
                  'isCompany': true,
                },
              );
            } else if (state is RegisterSellerErrorState) {
              AppToast.showError(context, state.message);
            } else if (state is UploadFileErrorState) {
              AppToast.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading =
                state is RegisterSellerLoadingState ||
                state is UploadFileLoadingState;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 16.h),
                    const AuthHeader(),
                    SizedBox(height: 24.h),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: _registerWithoutFiles,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 6.w,
                                horizontal: 8.w,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    S.of(context).skip,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      color: LightColor.defaultColor,
                                      decorationColor: LightColor.defaultColor,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push(AppRoutes.kLoginView),
                                    child: SvgPicture.asset(
                                      isAr
                                          ? AppAssets.backIconAR
                                          : AppAssets.backIconEN,
                                      width: 24.w,
                                      height: 24.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          S.of(context).createAccount,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    Row(
                      children: [
                        Text(
                          S.of(context).uploadTradeLicense,

                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          S.of(context).optional,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: LightColor.hintColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    InkWell(
                      onTap: _pickTradeLicense,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 22.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE8EDF4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: _tradeLicenseFile == null
                            ? Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      AppAssets.uploadIcon,
                                      width: 24.w,
                                      height: 24.h,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    S.of(context).dragDropOrTapToUpload,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF4A4A4A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    S.of(context).pdfJpgPngMax10Mb,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: LightColor.hintColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        child: Image.file(
                                          File(_tradeLicenseFile!),
                                          width: double.infinity,
                                          height: 140.h,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8.h,
                                        right: 8.w,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _tradeLicenseFile = null;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4.w),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    S.of(context).tradeLicenseSelected,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF4A4A4A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Text(
                          S.of(context).uploadCompanySiteImages,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          S.of(context).optional,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: LightColor.hintColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    InkWell(
                      onTap: _pickCompanySiteImages,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 22.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE8EDF4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: _companySiteImages.isEmpty
                            ? Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      AppAssets.uploadIcon,
                                      width: 24.w,
                                      height: 24.h,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    S.of(context).dragDropOrTapToUpload,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF4A4A4A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    S.of(context).pdfJpgPngMax10Mb,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: LightColor.hintColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    height: 140.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _companySiteImages.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(width: 10.w),
                                      itemBuilder: (context, index) {
                                        final imagePath =
                                            _companySiteImages[index];
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              child: Image.file(
                                                File(imagePath),
                                                width: 140.w,
                                                height: 140.h,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 8.h,
                                              right: 8.w,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _companySiteImages.removeAt(
                                                      index,
                                                    );
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(4.w),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    '${S.of(context).companySiteImageSelected} (${_companySiteImages.length})',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF4A4A4A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    PrimaryButton(
                      text: S.of(context).confirm,
                      onPressed: isLoading ? null : _onConfirm,
                      isLoading: isLoading,
                      backgroundColor: LightColor.defaultColor,
                      borderRadius: 10,
                    ),
                    SizedBox(height: 16.h),
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
