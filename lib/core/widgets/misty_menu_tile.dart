import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A settings / profile row: leading glyph bubble, title, optional subtitle
/// and a trailing chevron (or any trailing widget, e.g. a toggle).
class MistyMenuTile extends StatelessWidget {
  const MistyMenuTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Replaces [icon] — e.g. a brand SVG.
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color ink = destructive ? AppColors.coral : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        child: Row(
          children: <Widget>[
            leading ??
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: destructive
                        ? AppColors.coralSoft
                        : AppColors.lavender,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon ?? Icons.circle, color: ink, size: 21),
                ),
            const SizedBox(width: AppSizes.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.body(
                      15,
                      weight: FontWeight.w600,
                      color: destructive
                          ? AppColors.coral
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            trailing ??
                (destructive
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      )),
          ],
        ),
      ),
    );
  }
}
