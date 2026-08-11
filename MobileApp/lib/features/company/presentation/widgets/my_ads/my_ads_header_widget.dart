import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

class MyAdsHeaderWidget extends StatelessWidget {
  const MyAdsHeaderWidget({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SearchHeader(
      title: showBackButton ? S.of(context).account : null,
      isBackButton: showBackButton,
    );
  }
}
