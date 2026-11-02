import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_availability_slot.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_segmented_control.dart';
import '../../../../data/models/availability.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/month_calendar.dart';
import '../widgets/slot_editor_sheet.dart';

/// "Set Your Availability" — the Calendar tab, reproduced from the second
/// reference screen.
class SetAvailabilityScreen extends ConsumerStatefulWidget {
  const SetAvailabilityScreen({super.key});

  @override
  ConsumerState<SetAvailabilityScreen> createState() =>
      _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends ConsumerState<SetAvailabilityScreen> {
  int _view = 0;
  DateTime _selected = Fmt.dateOnly(DateTime.now());
  late DateTime _month = DateTime(_selected.year, _selected.month);
  bool _saving = false;

  AvailabilityController get _ctrl => ref.read(availabilityProvider.notifier);

  Future<void> _edit(DateTime day, [AvailabilitySlot? slot]) {
    final bool isNew = slot == null;
    final List<AvailabilitySlot> existing = _ctrl.slotsFor(day);
    // A new slot starts where the day's last slot ends (or at 6 PM).
    final TimeOfDay start = existing.isEmpty
        ? const TimeOfDay(hour: 18, minute: 0)
        : existing.last.end;
    final AvailabilitySlot initial =
        slot ??
        AvailabilitySlot(
          id: _ctrl.newId(),
          start: start,
          end: TimeOfDay(
            hour: (start.hour + 1).clamp(0, 23),
            minute: start.minute,
          ),
        );
    return showSlotEditor(
      context,
      day: day,
      initial: initial,
      isNew: isNew,
      onSave: (AvailabilitySlot s) => _ctrl.upsert(day, s),
    );
  }

  Future<void> _delete(DateTime day, AvailabilitySlot slot) async {
    if (slot.partiallyBooked) {
      final bool ok = await AppFeedback.confirm(
        context,
        title: 'Remove a booked slot?',
        message:
            'A client has already booked part of this slot. We’ll ask them '
            'to reschedule.',
        confirmLabel: 'Remove',
        destructive: true,
      );
      if (!ok) return;
    }
    _ctrl.remove(day, slot.id);
  }

  Future<void> _save() async {
    final List<DateTime> short = _ctrl.daysBelowMinimum();
    if (short.isNotEmpty) {
      AppFeedback.toast(
        context,
        '${Fmt.dayDate(short.first)} has less than 2 hours. '
        'Add time or remove it.',
      );
      setState(() {
        _selected = short.first;
        _month = DateTime(short.first.year, short.first.month);
        _view = 0;
      });
      return;
    }
    setState(() => _saving = true);
    final bool ok = await AppFeedback.guard(context, _ctrl.save);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) AppFeedback.toast(context, 'Availability saved');
  }

  void _help() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          0,
          AppSizes.screenPadding,
          AppSizes.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('How availability works', style: AppTypography.displaySmall),
            const SizedBox(height: AppSizes.md),
            for (final String line in <String>[
              'Pick a date, then add one or more time slots.',
              'Each day you open needs at least 2 hours in total.',
              'Clients can book sessions inside your slots.',
              'During a slot you can also go online for Talk Now requests.',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(line, style: AppTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AvailabilityMap data =
        ref.watch(availabilityProvider).valueOrNull ??
        <DateTime, List<AvailabilitySlot>>{};

    DayMark markFor(DateTime day) {
      final List<AvailabilitySlot>? slots = data[Fmt.dateOnly(day)];
      if (slots == null || slots.isEmpty) return DayMark.none;
      return slots.any((AvailabilitySlot s) => s.partiallyBooked)
          ? DayMark.partiallyBooked
          : DayMark.available;
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          MistyAppBar(
            onBack: () => context.go(AppRoutes.home),
            trailing: TextButton.icon(
              onPressed: _help,
              icon: const Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              label: Text(
                AppStrings.help,
                style: AppTypography.body(
                  14.5,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.sm,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              children: <Widget>[
                Text(
                  AppStrings.setYourAvailability,
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  AppStrings.availabilitySubtitle,
                  style: AppTypography.body(
                    14.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                MistySegmentedControl(
                  segments: const <String>[
                    AppStrings.calendarView,
                    AppStrings.listView,
                  ],
                  selected: _view,
                  onChanged: (int v) => setState(() => _view = v),
                ),
                const SizedBox(height: AppSizes.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _view == 0
                      ? Column(
                          key: const ValueKey<String>('calendar'),
                          children: <Widget>[
                            MonthCalendar(
                              month: _month,
                              selected: _selected,
                              markFor: markFor,
                              onSelect: (DateTime d) =>
                                  setState(() => _selected = d),
                              onMonthChanged: (DateTime m) =>
                                  setState(() => _month = m),
                            ),
                            const SizedBox(height: AppSizes.md),
                            _DayCard(
                              day: _selected,
                              slots:
                                  data[_selected] ?? const <AvailabilitySlot>[],
                              onAdd: () => _edit(_selected),
                              onEdit: (AvailabilitySlot s) =>
                                  _edit(_selected, s),
                              onDelete: (AvailabilitySlot s) =>
                                  _delete(_selected, s),
                            ),
                          ],
                        )
                      : _ListViewBody(
                          key: const ValueKey<String>('list'),
                          data: data,
                          onAdd: (DateTime d) => _edit(d),
                          onEdit: _edit,
                          onDelete: _delete,
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.xs,
              AppSizes.screenPadding,
              AppSizes.md,
            ),
            child: MistyPrimaryButton(
              label: AppStrings.saveAvailability,
              isLoading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected day's slots plus the dashed "Add Time Slot" button.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.slots,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime day;
  final List<AvailabilitySlot> slots;
  final VoidCallback onAdd;
  final ValueChanged<AvailabilitySlot> onEdit;
  final ValueChanged<AvailabilitySlot> onDelete;

  @override
  Widget build(BuildContext context) {
    return MistyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            Fmt.longDate(day),
            style: AppTypography.body(16.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.md),
          for (final AvailabilitySlot s in slots) ...<Widget>[
            MistyAvailabilitySlot(
              start: s.start,
              end: s.end,
              duration: s.duration,
              note: s.partiallyBooked ? '${s.bookedMinutes} min booked' : null,
              onEdit: () => onEdit(s),
              onDelete: () => onDelete(s),
            ),
            const SizedBox(height: AppSizes.sm + 2),
          ],
          if (slots.isEmpty) ...<Widget>[
            Text(
              'No time set for this day yet.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSizes.md),
          ],
          _AddSlotButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _AddSlotButton extends StatelessWidget {
  const _AddSlotButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorder(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSizes.brMd,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
                const SizedBox(width: AppSizes.sm + 2),
                Text(
                  AppStrings.addTimeSlot,
                  style: AppTypography.body(
                    15,
                    weight: FontWeight.w500,
                    color: AppColors.primary,
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

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.primaryMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppSizes.radiusMd),
        ),
      );
    for (final PathMetric m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Upcoming days that carry availability, each with its slots.
class _ListViewBody extends StatelessWidget {
  const _ListViewBody({
    super.key,
    required this.data,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final AvailabilityMap data;
  final ValueChanged<DateTime> onAdd;
  final void Function(DateTime, AvailabilitySlot) onEdit;
  final void Function(DateTime, AvailabilitySlot) onDelete;

  @override
  Widget build(BuildContext context) {
    final DateTime today = Fmt.dateOnly(DateTime.now());
    final List<DateTime> days =
        data.keys.where((DateTime d) => !d.isBefore(today)).toList()..sort();

    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Text(
          'No upcoming availability. Switch to Calendar View to add some.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final DateTime d in days) ...<Widget>[
          _DayCard(
            day: d,
            slots: data[d]!,
            onAdd: () => onAdd(d),
            onEdit: (AvailabilitySlot s) => onEdit(d, s),
            onDelete: (AvailabilitySlot s) => onDelete(d, s),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}
