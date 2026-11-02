import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The white rounded surface nearly every block in the app sits on.
class MistyCard extends StatelessWidget {
  const MistyCard({
    super.key,
    required this.child,
    this.padding = AppSizes.cardInsets,
    this.color = AppColors.surface,
    this.gradient,
    this.borderColor,
    this.radius = AppSizes.radiusLg,
    this.onTap,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: br,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.1),
        boxShadow: shadow ? AppColors.softShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The violet hero card (earnings total, profile header).
class MistyGradientCard extends StatelessWidget {
  const MistyGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.xl),
    this.gradient = AppColors.heroGradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppSizes.brCard,
        boxShadow: AppColors.liftedShadow,
      ),
      child: ClipRRect(
        borderRadius: AppSizes.brCard,
        child: Stack(
          children: <Widget>[
            // Two soft light pools keep the fill from looking flat.
            Positioned(right: -40, top: -50, child: _glow(170, 0.16)),
            Positioned(left: -30, bottom: -70, child: _glow(150, 0.10)),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

/// The lavender "i" note used under forms and on the Talk Now screens.
class MistyInfoNote extends StatelessWidget {
  const MistyInfoNote({
    super.key,
    required this.text,
    this.icon = Icons.info_rounded,
    this.iconColor = AppColors.primary,
    this.color = AppColors.lavender,
    this.center = false,
  });

  final String text;
  final IconData icon;
  final Color iconColor;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md + 2,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppSizes.brLg),
      child: Row(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section title with an optional trailing action ("View all").
class MistySectionHeader extends StatelessWidget {
  const MistySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSizes.md),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: AppTypography.headingSmall)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                child: Text(
                  actionLabel!,
                  style: AppTypography.body(
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A label / value row used inside detail cards.
class MistyInfoRow extends StatelessWidget {
  const MistyInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.leading,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Widget? leading;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: AppSizes.md),
          ],
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          const SizedBox(width: AppSizes.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.body(
                14.5,
                weight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft lavender chip (specialisations, concerns, filters).
class MistyChip extends StatelessWidget {
  const MistyChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.lavender,
        borderRadius: AppSizes.brPill,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.lavenderStrong,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSizes.brPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md + 2,
              vertical: AppSizes.sm,
            ),
            child: Text(
              label,
              style: AppTypography.body(
                13.5,
                weight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.primaryStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
