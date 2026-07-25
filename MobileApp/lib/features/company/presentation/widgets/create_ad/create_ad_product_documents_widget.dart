import 'dart:io';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
class CreateAdProductDocumentsWidget extends StatelessWidget {
  const CreateAdProductDocumentsWidget({
    super.key,
    required this.productDocuments,
    required this.onPickTap,
    required this.onRemove,
  });

  final List<String> productDocuments;
  final VoidCallback onPickTap;
  final ValueChanged<int> onRemove;

  bool _isImagePath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp';
  }

  Future<void> _openDocument(String path) async {
    final Uri uri;
    if (path.startsWith('http')) {
      uri = Uri.parse(ApiConstants.rewriteMediaUrl(path));
    } else if (path.startsWith('/') &&
        !path.startsWith('/data') &&
        !path.startsWith('/storage')) {
      uri = Uri.parse(ApiConstants.resolveMediaUrl(path));
    } else {
      uri = Uri.file(path);
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).productDocuments,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: onPickTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            ),
            child: productDocuments.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
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
                      SizedBox(height: 16.h),
                      Text(
                        S.of(context).tapToUploadImageOrFile,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: fontFamily,
                          color: LightColor.greyTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'JPG, PNG, PDF, DOC, DOCX, XLS, PPT',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: fontFamily,
                          color: const Color(0xFF333333).withOpacity(0.5),
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 100.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: productDocuments.length,
                          separatorBuilder: (_, __) => SizedBox(width: 10.w),
                          itemBuilder: (context, index) {
                            final filePath = productDocuments[index];
                            final isImage = _isImagePath(filePath);

                            return Stack(
                              children: [
                                InkWell(
                                  onTap: () => _openDocument(filePath),
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    width: 100.w,
                                    height: 100.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: isImage
                                          ? (filePath.startsWith('http') ||
                                                  filePath.startsWith('/product-')
                                              ? CachedAppImage(
                                                  imageUrl:
                                                      ApiConstants.resolveMediaUrl(
                                                    filePath,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorWidget: Icon(
                                                    Icons.insert_drive_file_rounded,
                                                    color: const Color(0xFF3A7DC5),
                                                    size: 36.sp,
                                                  ),
                                                )
                                              : Image.file(
                                                  File(filePath),
                                                  fit: BoxFit.cover,
                                                ))
                                          : Center(
                                              child: Icon(
                                                Icons.insert_drive_file_rounded,
                                                color: const Color(0xFF3A7DC5),
                                                size: 36.sp,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4.h,
                                  right: 4.w,
                                  child: InkWell(
                                    onTap: () => onRemove(index),
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14.sp,
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
                        S.of(context).selectedDocuments(productDocuments.length.toString()),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: fontFamily,
                          color: const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
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
}
