import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/availability.dart';

/// Bottom sheet to add or edit one slot.
///
/// [onSave] returns an error message to show inline, or null when the slot
/// was accepted (which closes the sheet).
Future<void> showSlotEditor(
  BuildContext context, {
  required DateTime day,
  required AvailabilitySlot initial,
  required bool isNew,
  required String? Function(AvailabilitySlot) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (BuildContext context) =>
        _SlotEditor(day: day, initial: initial, isNew: isNew, onSave: onSave),
  );
}

class _SlotEditor extends StatefulWidget {
  const _SlotEditor({
    required this.day,
    required this.initial,
    required this.isNew,
    required this.onSave,
  });

  final DateTime day;
  final AvailabilitySlot initial;
  final bool isNew;
  final String? Function(AvailabilitySlot) onSave;

  @override
  State<_SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends State<_SlotEditor> {
  late AvailabilitySlot _slot = widget.initial;
  String? _error;

  Future<void> _pick(bool start) async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: start ? _slot.start : _slot.end,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (t == null) return;
    setState(() {
      _error = null;
      _slot = start ? _slot.copyWith(start: t) : _slot.copyWith(end: t);
    });
  }

  void _duration(int hours) {
    final int end = _slot.start.hour * 60 + _slot.start.minute + hours * 60;
    if (end >= 24 * 60) {
      setState(() => _error = 'That runs past midnight.');
      return;
    }
    setState(() {
      _error = null;
      _slot = _slot.copyWith(
        end: TimeOfDay(hour: end ~/ 60, minute: end % 60),
      );
    });
  }

  void _save() {
    final String? error = widget.onSave(_slot);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        0,
        AppSizes.screenPadding,
        MediaQuery.viewInsetsOf(context).bottom + AppSizes.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.isNew ? 'Add time slot' : 'Edit time slot',
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(Fmt.longDate(widget.day), style: AppTypography.bodyMedium),
            const SizedBox(height: AppSizes.xl),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimeField(
                    label: 'Starts',
                    value: _slot.start,
                    onTap: () => _pick(true),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _TimeField(
                    label: 'Ends',
                    value: _slot.end,
                    onTap: () => _pick(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Wrap(
              spacing: AppSizes.sm,
              children: <Widget>[
                for (final int h in <int>[1, 2, 3, 4])
                  MistyChip(
                    label: h == 1 ? '1 hour' : '$h hours',
                    selected: _slot.duration.inMinutes == h * 60,
                    onTap: () => _duration(h),
                  ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _error == null
                  ? const SizedBox(height: AppSizes.xl)
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md,
                      ),
                      child: Text(
                        _error!,
                        style: AppTypography.body(13, color: AppColors.error),
                      ),
                    ),
            ),
            MistyPrimaryButton(label: 'Save Slot', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MistyCard(
      onTap: onTap,
      shadow: false,
      color: AppColors.lavender,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: <Widget>[
          const MistySvgIcon(AppAssets.iconClock, size: 36),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppTypography.caption),
                Text(
                  Fmt.timeOfDay(value),
                  style: AppTypography.body(16, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
