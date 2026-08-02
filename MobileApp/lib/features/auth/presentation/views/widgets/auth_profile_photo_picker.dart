import 'dart:io';
import 'dart:math' as math;

import 'package:alrasmarket/core/media/image_compressor.dart';
import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Optional profile photo picker for auth screens (register / login).
class AuthProfilePhotoPicker extends StatefulWidget {
  const AuthProfilePhotoPicker({
    super.key,
    this.initialPath,
    required this.onChanged,
  });

  final String? initialPath;
  final ValueChanged<String?> onChanged;

  @override
  State<AuthProfilePhotoPicker> createState() => _AuthProfilePhotoPickerState();
}

class _AuthProfilePhotoPickerState extends State<AuthProfilePhotoPicker> {
  String? _localPath;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _localPath = widget.initialPath;
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final source = await showImageSourceSheet(context);
      if (!mounted || source == null) return;

      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted || picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: LightColor.defaultColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: 'Crop image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (!mounted || cropped == null) return;

      final compressed =
          await ImageCompressor.compressIfNeeded(cropped.path) ?? cropped.path;
      setState(() => _localPath = compressed);
      widget.onChanged(compressed);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _clear() {
    setState(() => _localPath = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final path = _localPath;
    final size = 92.w;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: _picking ? null : _pick,
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  color: LightColor.defaultColor.withValues(alpha: 0.75),
                  strokeWidth: 1.6,
                ),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Center(
                    child: path != null
                        ? ClipOval(
                            child: Image.file(
                              File(path),
                              width: size - 10.w,
                              height: size - 10.w,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              color: LightColor.defaultColor.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: LightColor.defaultColor,
                              size: 26.sp,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (_picking)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (path != null && !_picking)
              Positioned(
                top: -2.h,
                right: -2.w,
                child: GestureDetector(
                  onTap: _clear,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, size: 14.sp, color: Colors.black54),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: _picking ? null : _pick,
          child: Text(
            s.uploadProfilePhoto,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: LightColor.defaultColor,
              decoration: TextDecoration.underline,
              decorationColor: LightColor.defaultColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 28;
    const gapFactor = 0.45;
    final sweep = (2 * math.pi) / dashCount;
    final dashSweep = sweep * (1 - gapFactor);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
