import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The soft iOS-style switch from the references: mint for presence, violet
/// for preferences, a pale grey track when off.
class MistyToggle extends StatelessWidget {
  const MistyToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.primary,
    this.width = 54,
    this.height = 32,
    this.semanticLabel,
  });

  const MistyToggle.mint({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 58,
    this.height = 34,
    this.semanticLabel,
  }) : activeColor = AppColors.mint;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final double width;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double knob = height - 6;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? activeColor : AppColors.toggleOff,
            borderRadius: BorderRadius.circular(height),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
