import 'dart:io';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_thumbnail.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdProductImagesWidget extends StatelessWidget {
  const CreateAdProductImagesWidget({
    super.key,
    required this.productImages,
    required this.onPickTap,
    required this.onRemove,
    this.isCompressingMedia = false,
    this.mediaCompressionProgress = 0,
    this.mediaCompressionLabel,
  });

  final List<String> productImages;
  final VoidCallback onPickTap;
  final ValueChanged<int> onRemove;
  final bool isCompressingMedia;
  final double mediaCompressionProgress;
  final String? mediaCompressionLabel;

  bool _isVideoPath(String path) => CreateAdFormMapper.isVideoPath(path);

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return CreateAdSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CreateAdFieldIcon(Icons.image_outlined),
              SizedBox(width: 10.w),
              Expanded(
                child: CreateAdRequiredLabel(
                  S.of(context).productImages,
                  fontFamily: fontFamily,
                  required: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          InkWell(
            onTap: onPickTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _DashedRRectPainter(
                    color: CreateAdDesign.brand.withValues(alpha: 0.45),
                    radius: 12.r,
                  ),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: CreateAdDesign.iconBg.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: productImages.isEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: CreateAdDesign.cardShadow,
                                ),
                                child: Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 22.sp,
                                  color: CreateAdDesign.brand,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                S.of(context).tapToUploadImageOrVideo,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontFamily: fontFamily,
                                  color: CreateAdDesign.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'jpg, png, mp4 (max ${CreateAdFormMapper.maxProductVideoSizeMb} MB, ${CreateAdFormMapper.maxProductVideoDurationSeconds}s)',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontFamily: fontFamily,
                                  color: CreateAdDesign.muted,
                                  fontWeight: FontWeight.w500,
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
                                  itemCount: productImages.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 10.w),
                                  itemBuilder: (context, index) {
                                    final filePath = productImages[index];
                                    final isVideo = _isVideoPath(filePath);
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100.w,
                                          height: 100.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F5),
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            child: isVideo
                                                ? ProductVideoThumbnail(
                                                    videoUrl:
                                                        _resolveVideoSource(
                                                      filePath,
                                                    ),
                                                    width: 100.w,
                                                    height: 100.h,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12.r,
                                                    ),
                                                  )
                                                : _buildImagePreview(filePath),
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
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  20.r,
                                                ),
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
                                S.of(context).selectedMedia(
                                      productImages.length.toString(),
                                    ),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontFamily: fontFamily,
                                  color: CreateAdDesign.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                if (isCompressingMedia)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mediaCompressionLabel ?? 'Compressing...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: fontFamily,
                                color: CreateAdDesign.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: LinearProgressIndicator(
                                value:
                                    mediaCompressionProgress.clamp(0.0, 1.0),
                                minHeight: 8.h,
                                backgroundColor: const Color(0xFFE8EEF5),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  CreateAdDesign.brand,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              '${(mediaCompressionProgress.clamp(0.0, 1.0) * 100).round()}%',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontFamily: fontFamily,
                                color: CreateAdDesign.brand,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isRemotePath(String path) {
    return CreateAdFormMapper.isRemoteAssetPath(path);
  }

  String _resolveRemoteUrl(String path) => ApiConstants.resolveMediaUrl(path);

  String _resolveVideoSource(String path) {
    if (_isRemotePath(path)) {
      return _resolveRemoteUrl(path);
    }
    return path;
  }

  Widget _buildImagePreview(String filePath) {
    if (_isRemotePath(filePath)) {
      return CachedAppImage(
        imageUrl: _resolveRemoteUrl(filePath),
        fit: BoxFit.cover,
        errorWidget: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      );
    }
    return Image.file(File(filePath), fit: BoxFit.cover);
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: 7, gapLength: 5);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        dest.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
