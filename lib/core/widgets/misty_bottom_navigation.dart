import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MistyNavItem {
  const MistyNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;

  /// Pre-built SVG assets (see `AppAssets.navActive` / `navInactive`).
  final String activeIcon;
  final String inactiveIcon;
}

/// The reference tab bar: a white bar with a hairline top edge; the selected
/// item shows its brand-gradient glyph with a violet label, the rest a muted
/// lavender-grey glyph.
class MistyBottomNavigation extends StatelessWidget {
  const MistyBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<MistyNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.navHeight,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MistyNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: SvgPicture.asset(
                selected ? item.activeIcon : item.inactiveIcon,
                width: 26,
                height: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.body(
                11,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                height: 1.1,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
