import 'dart:io';

import 'package:alrasmarket/core/media/image_compressor.dart';
import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/profile_avatar.dart';
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

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _picking ? null : _pick,
              child: path != null
                  ? ClipOval(
                      child: Image.file(
                        File(path),
                        width: 88.w,
                        height: 88.w,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ProfileAvatar(size: 88.w, fallbackText: '+'),
            ),
            if (_picking)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (path != null && !_picking)
              GestureDetector(
                onTap: _clear,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16.sp, color: Colors.black54),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        TextButton.icon(
          onPressed: _picking ? null : _pick,
          icon: Icon(Icons.camera_alt_outlined, size: 18.sp),
          label: Text(
            s.uploadProfilePhoto,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
