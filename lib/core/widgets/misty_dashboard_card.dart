import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'misty_cards.dart';
import 'misty_svg_icon.dart';

/// One tile of the dashboard grid: brand icon tile, bold title, then either a
/// muted hint ("Block your time slots") or a value line ("3 today",
/// "₹8,400 this month").
class MistyDashboardCard extends StatelessWidget {
  const MistyDashboardCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.valueCaption,
    this.onTap,
  });

  final String icon;
  final String title;
  final String? subtitle;

  /// A prominent figure under the title (e.g. "₹8,400").
  final String? value;
  final String? valueCaption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MistyCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md + 2,
        AppSizes.md + 2,
        AppSizes.md,
        AppSizes.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MistySvgIcon(icon, size: 52),
          const SizedBox(height: AppSizes.md),
          // Scales down rather than truncating ("Upcoming Sessions").
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: AppTypography.body(
                15,
                weight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (value != null)
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: value,
                    style: AppTypography.body(
                      valueCaption == null ? 16 : 20,
                      weight: valueCaption == null
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: valueCaption == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (valueCaption != null)
                    TextSpan(
                      text: '\n$valueCaption',
                      style: AppTypography.body(
                        13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            )
          else if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
