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
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class HeaderProfileAvatar extends StatelessWidget {
  const HeaderProfileAvatar({super.key});

  static String _avatarInitial(AuthService auth) {
    final source = (auth.currentUserName ?? auth.currentUserEmail ?? '').trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return ProfileAvatar(
      size: 30.w,
      imagePath: auth.currentUserImagePath,
      fallbackText: _avatarInitial(auth),
    );
  }
}
