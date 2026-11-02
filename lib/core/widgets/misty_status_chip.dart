import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ChipTone { violet, mint, amber, coral, grey }

/// A small rounded status label ("Upcoming", "Completed", "Verified").
class MistyStatusChip extends StatelessWidget {
  const MistyStatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.violet,
    this.dot = false,
  });

  final String label;
  final ChipTone tone;
  final bool dot;

  static (Color, Color) colorsFor(ChipTone tone) => switch (tone) {
    ChipTone.violet => (AppColors.primarySoft, AppColors.primary),
    ChipTone.mint => (AppColors.mintSoft, AppColors.mintInk),
    ChipTone.amber => (AppColors.amberSoft, AppColors.amber),
    ChipTone.coral => (AppColors.coralSoft, AppColors.coral),
    ChipTone.grey => (AppColors.surfaceMuted, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color ink) = colorsFor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppSizes.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.body(
              12,
              weight: FontWeight.w600,
              color: ink,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The presence dot, gently pulsing while live.
class PresenceDot extends StatefulWidget {
  const PresenceDot({
    super.key,
    required this.color,
    this.size = 12,
    this.pulse = false,
  });

  final Color color;
  final double size;
  final bool pulse;

  @override
  State<PresenceDot> createState() => _PresenceDotState();
}

class _PresenceDotState extends State<PresenceDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat();
  }

  @override
  void didUpdateWidget(PresenceDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) _c.repeat();
    if (!widget.pulse && _c.isAnimating) _c.reset();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    return SizedBox(
      width: s * 2,
      height: s * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) => Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (widget.pulse)
              Container(
                width: s * (1 + _c.value),
                height: s * (1 + _c.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
                ),
              ),
            child!,
          ],
        ),
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
