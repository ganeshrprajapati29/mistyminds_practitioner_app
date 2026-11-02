import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The filled violet gradient pill every primary action uses.
class MistyPrimaryButton extends StatelessWidget {
  const MistyPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailingIcon,
    this.isLoading = false,
    this.height = AppSizes.buttonHeight,
    this.gradient = AppColors.ctaGradient,
  });

  final String label;
  final VoidCallback? onPressed;

  /// A widget before the label (an icon, or the welcome button's bubble).
  final Widget? leading;
  final IconData? trailingIcon;
  final bool isLoading;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppSizes.brPill,
              boxShadow: enabled ? AppColors.buttonGlow : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                borderRadius: AppSizes.brPill,
                child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      : _content(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final Widget text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppTypography.buttonText,
    );

    // With a leading bubble the label stays optically centred, as in the
    // welcome reference, and the arrow pins to the right edge.
    if (leading != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: height * 0.12),
        child: Row(
          children: <Widget>[
            leading!,
            Expanded(child: text),
            SizedBox(
              width: height * 0.72,
              child: trailingIcon == null
                  ? null
                  : Icon(trailingIcon, color: Colors.white, size: 26),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(child: text),
          if (trailingIcon != null) ...<Widget>[
            const SizedBox(width: AppSizes.sm),
            Icon(trailingIcon, color: Colors.white, size: AppSizes.iconMd),
          ],
        ],
      ),
    );
  }
}

/// The white outlined pill ("Not now", "Pause Availability", "End Session").
class MistySecondaryButton extends StatelessWidget {
  const MistySecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.color = AppColors.textPrimary,
    this.borderColor = AppColors.border,
    this.background = AppColors.surface,
    this.height = AppSizes.buttonHeight,
    this.radius = AppSizes.radiusPill,
    this.fontSize = 16,
  });

  /// The coral "End Session" / destructive variant.
  const MistySecondaryButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.height = AppSizes.buttonHeight,
    this.radius = AppSizes.radiusPill,
    this.fontSize = 16,
  }) : color = AppColors.coral,
       borderColor = AppColors.coralBorder,
       background = AppColors.coralSoft;

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Color color;
  final Color borderColor;
  final Color background;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: br,
        side: BorderSide(color: borderColor, width: 1.3),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: br,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSizes.sm),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTypography.body(
                        fontSize,
                        weight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round white header button (back, help, filters) from the references.
class MistyIconButton extends StatelessWidget {
  const MistyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 42,
    this.child,
  });

  const MistyIconButton.back({
    super.key,
    required this.onPressed,
    this.size = 42,
  }) : icon = Icons.chevron_left_rounded,
       tooltip = 'Back',
       child = null;

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  /// Replaces [icon] — for an SVG glyph with a badge.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child:
                child ??
                Icon(icon, color: AppColors.textPrimary, size: size * 0.62),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// A plain text link with an optional trailing arrow.
class MistyLinkButton extends StatelessWidget {
  const MistyLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.arrow = false,
    this.style,
  });

  final String label;
  final VoidCallback onPressed;
  final bool arrow;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextStyle s = style ?? AppTypography.link;
    return InkWell(
      onTap: onPressed,
      borderRadius: AppSizes.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.sm,
          horizontal: AppSizes.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: Text(label, style: s)),
            if (arrow) ...<Widget>[
              const SizedBox(width: AppSizes.sm),
              Icon(
                Icons.arrow_forward_rounded,
                size: (s.fontSize ?? 15) + 5,
                color: s.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
