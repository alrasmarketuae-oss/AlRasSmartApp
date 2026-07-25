import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/profile_image_url.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    this.imagePath,
    this.fallbackText,
    this.gradient,
    this.revision,
  });

  final double size;
  final String? imagePath;
  final String? fallbackText;
  final Gradient? gradient;
  final int? revision;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.instance.profileImageRevision,
      builder: (context, _, __) {
        final url = profileImageUrlFromPath(
          imagePath ?? AuthService.instance.currentUserImagePath,
          revision: revision,
        );
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient ??
                const LinearGradient(
                  begin: Alignment(0, 1),
                  end: Alignment(-0.5, 0),
                  colors: [
                    Color.fromRGBO(34, 145, 237, 1),
                    Color.fromRGBO(69, 171, 255, 1),
                  ],
                ),
          ),
          clipBehavior: Clip.antiAlias,
          child: url != null
              ? CachedAppImage(
                  key: ValueKey(url),
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorWidget: _fallback(),
                )
              : _fallback(),
        );
      },
    );
  }

  Widget _fallback() {
    final text = (fallbackText ?? '?').substring(0, 1).toUpperCase();
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.42,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class HeaderProfileAvatar extends StatelessWidget {
  const HeaderProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.instance.profileImageRevision,
      builder: (context, _, __) {
        final url = AuthService.instance.currentProfileImageUrl;
        return Container(
          width: 30.w,
          height: 30.h,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE9EEF5),
          ),
          clipBehavior: Clip.antiAlias,
          child: url != null
              ? CachedAppImage(
                  key: ValueKey(url),
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: 30.w,
                  height: 30.h,
                  errorWidget:
                      Icon(Icons.person, size: 18.sp, color: Colors.grey),
                )
              : Icon(Icons.person, size: 18.sp, color: Colors.grey),
        );
      },
    );
  }
}
