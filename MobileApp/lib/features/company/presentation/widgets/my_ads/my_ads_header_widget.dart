import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

class MyAdsHeaderWidget extends StatelessWidget {
  const MyAdsHeaderWidget({
    super.key,
    this.showBackButton = true,
    this.title,
  });

  final bool showBackButton;
  final String? title;

  @override
  Widget build(BuildContext context) {
    // No search on Account — keeps listings visible below.
    return SearchHeader(
      title: title ?? (showBackButton ? S.of(context).account : null),
      isBackButton: showBackButton,
      isSearch: false,
    );
  }
}
