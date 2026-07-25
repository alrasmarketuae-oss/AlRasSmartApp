import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthHeader extends StatelessWidget {
  final bool isRecording;
  const AuthHeader({super.key, this.isRecording = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          LanguageButton(),
          Spacer(),
          if (!isRecording)
            Image.asset(AppAssets.logo, width: 52.w, height: 42.h),
        ],
      ),
    );
  }
}
