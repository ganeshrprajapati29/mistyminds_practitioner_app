import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';
import 'misty_buttons.dart';

/// The reference header: a round back button on the left, an optional title,
/// and an optional trailing action. Not a Material AppBar — it scrolls with
/// the page and carries no elevation.
class MistyAppBar extends StatelessWidget {
  const MistyAppBar({
    super.key,
    this.title,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSizes.screenPadding,
      AppSizes.md,
      AppSizes.screenPadding,
      AppSizes.sm,
    ),
  });

  final String? title;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 44,
        child: Row(
          children: <Widget>[
            if (showBack)
              MistyIconButton.back(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: 42),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Text(
                      title!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium,
                    ),
            ),
            SizedBox(width: trailing == null ? 42 : null, child: trailing),
          ],
        ),
      ),
    );
  }
}

/// A tab-root title row ("Clients", "Earnings") with an optional action.
class MistyPageTitle extends StatelessWidget {
  const MistyPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        AppSizes.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTypography.displayMedium),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSizes.xs),
                  Text(subtitle!, style: AppTypography.bodyMedium),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
