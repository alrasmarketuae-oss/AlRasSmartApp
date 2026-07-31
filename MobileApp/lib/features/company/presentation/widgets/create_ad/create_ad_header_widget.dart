import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_hero_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdHeaderWidget extends StatelessWidget {
  const CreateAdHeaderWidget({super.key, this.showBack = false});

  /// Shown when the form was pushed (editing an ad) instead of hosted as the
  /// company home tab, where there is nothing to go back to.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchHeader(
          title: null,
          isBackButton: showBack,
          isSearch: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: const CreateAdHeroBanner(),
        ),
      ],
    );
  }
}
