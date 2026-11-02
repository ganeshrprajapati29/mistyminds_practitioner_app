import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The pill toggle from the availability reference ("Calendar View" /
/// "List View"): the selected segment is a filled violet pill.
class MistySegmentedControl extends StatelessWidget {
  const MistySegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 44,
  });

  final List<String> segments;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.lavender,
        borderRadius: AppSizes.brPill,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < segments.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == selected ? AppColors.ctaGradient : null,
                    borderRadius: AppSizes.brPill,
                    boxShadow: i == selected ? AppColors.softShadow : null,
                  ),
                  child: Text(
                    segments[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      14,
                      weight: i == selected ? FontWeight.w600 : FontWeight.w500,
                      color: i == selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
