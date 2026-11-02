import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_cards.dart';

enum DayMark { none, available, partiallyBooked }

/// The month grid from the availability reference: Monday-first weeks,
/// round day cells, a violet fill for the selected day, lavender fills for
/// days that already carry availability, and a legend underneath.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.markFor,
    required this.onSelect,
    required this.onMonthChanged,
  });

  /// Any date inside the month to show.
  final DateTime month;
  final DateTime selected;
  final DayMark Function(DateTime day) markFor;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime first = DateTime(month.year, month.month);
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final int leading = first.weekday - 1;
    final int cells = ((leading + daysInMonth) / 7).ceil() * 7;
    final DateTime today = Fmt.dateOnly(DateTime.now());
    final bool canGoBack = first.isAfter(DateTime(today.year, today.month));

    return MistyCard(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _MonthArrow(
                icon: Icons.chevron_left_rounded,
                onTap: canGoBack
                    ? () =>
                          onMonthChanged(DateTime(month.year, month.month - 1))
                    : null,
              ),
              Expanded(
                child: Text(
                  Fmt.monthYear(first),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(16.5, weight: FontWeight.w600),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: <Widget>[
              for (final String d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      12.5,
                      weight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          for (int row = 0; row < cells ~/ 7; row++)
            Row(
              children: <Widget>[
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(
                      row * 7 + col - leading + 1,
                      daysInMonth,
                      today,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSizes.sm),
          const _Legend(),
        ],
      ),
    );
  }

  Widget _cell(int dayNumber, int daysInMonth, DateTime today) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 44);
    }
    final DateTime day = DateTime(month.year, month.month, dayNumber);
    final bool past = day.isBefore(today);
    final bool isSelected = Fmt.sameDay(day, selected);
    final bool isToday = Fmt.sameDay(day, today);
    final DayMark mark = past ? DayMark.none : markFor(day);

    final Color fill = isSelected
        ? AppColors.primary
        : switch (mark) {
            DayMark.partiallyBooked => AppColors.lavenderStrong,
            DayMark.available => AppColors.lavender,
            DayMark.none => Colors.transparent,
          };
    final Color ink = isSelected
        ? Colors.white
        : past
        ? AppColors.textTertiary
        : AppColors.textPrimary;

    return Semantics(
      button: !past,
      selected: isSelected,
      label: Fmt.longDate(day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: past ? null : () => onSelect(day),
        child: SizedBox(
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primaryMuted, width: 1.4)
                      : null,
                ),
                child: Text(
                  '$dayNumber',
                  style: AppTypography.body(
                    14,
                    weight: isSelected || isToday
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: ink,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mark == DayMark.available && !isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lavender,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget swatch, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        swatch,
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.body(11, color: AppColors.textSecondary),
        ),
      ],
    );
    Widget dot(Color c, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: AppSizes.md,
      runSpacing: AppSizes.xs,
      children: <Widget>[
        item(dot(AppColors.primary, 11), AppStrings.legendSelected),
        item(dot(AppColors.lavenderStrong, 11), AppStrings.legendPartial),
        item(dot(AppColors.primary, 5), AppStrings.legendAvailable),
      ],
    );
  }
}
