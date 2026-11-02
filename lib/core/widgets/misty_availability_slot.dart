import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// A lavender time-slot row: "6:00 PM – 8:00 PM / 2 hours" with edit and
/// delete actions, as in the availability reference.
class MistyAvailabilitySlot extends StatelessWidget {
  const MistyAvailabilitySlot({
    super.key,
    required this.start,
    required this.end,
    required this.duration,
    this.note,
    this.onEdit,
    this.onDelete,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final Duration duration;

  /// Extra context, e.g. "50 min booked".
  final String? note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md + 2,
        AppSizes.sm + 2,
        AppSizes.xs,
        AppSizes.sm + 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lavender,
        borderRadius: AppSizes.brMd,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${Fmt.timeOfDay(start)} – ${Fmt.timeOfDay(end)}',
                  style: AppTypography.body(
                    15,
                    weight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note == null
                      ? Fmt.hoursLabel(duration)
                      : '${Fmt.hoursLabel(duration)} · $note',
                  style: AppTypography.body(
                    12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit slot',
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 21,
              ),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete slot',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.coral,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}
