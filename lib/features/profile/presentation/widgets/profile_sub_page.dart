import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/misty_app_bar.dart';

/// Frame shared by every profile sub-screen: header + padded scroll body.
class ProfileSubPage extends StatelessWidget {
  const ProfileSubPage({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          MistyAppBar(title: title, trailing: trailing),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.sm,
                AppSizes.screenPadding,
                AppSizes.xxl,
              ),
              children: children,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.xs,
                AppSizes.screenPadding,
                AppSizes.md,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}
