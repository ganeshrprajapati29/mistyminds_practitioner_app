import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_toggle.dart';
import '../../../../data/models/settings.dart';
import '../../../../state/providers.dart';
import '../widgets/profile_sub_page.dart';

class AvailabilityPreferencesScreen extends ConsumerStatefulWidget {
  const AvailabilityPreferencesScreen({super.key});

  @override
  ConsumerState<AvailabilityPreferencesScreen> createState() =>
      _AvailabilityPreferencesScreenState();
}

class _AvailabilityPreferencesScreenState
    extends ConsumerState<AvailabilityPreferencesScreen> {
  String _length = '50 min';
  String _buffer = '10 min';
  String _notice = '4 hours';
  bool _autoOnline = false;
  bool _weekends = true;
  bool _seeded = false;
  bool _saving = false;

  /// Starts the form from what's saved on the account (once, when loaded).
  void _seed(PractitionerSettings? s) {
    if (_seeded || s == null) return;
    _seeded = true;
    final Map<String, Object> a = s.availability;
    _length = a['sessionLength'] as String? ?? _length;
    _buffer = a['breakBetween'] as String? ?? _buffer;
    _notice = a['minimumNotice'] as String? ?? _notice;
    _autoOnline = a['remindToGoOnline'] as bool? ?? _autoOnline;
    _weekends = a['openWeekends'] as bool? ?? _weekends;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref
          .read(settingsProvider.notifier)
          .setAvailabilityPreferences(<String, Object>{
            'sessionLength': _length,
            'breakBetween': _buffer,
            'minimumNotice': _notice,
            'remindToGoOnline': _autoOnline,
            'openWeekends': _weekends,
          }),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    AppFeedback.toast(context, 'Preferences saved');
    context.pop();
  }

  Widget _choices(
    String title,
    List<String> options,
    String value,
    ValueChanged<String> onPick,
  ) => MistyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTypography.title),
        const SizedBox(height: AppSizes.sm + 2),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: <Widget>[
            for (final String o in options)
              MistyChip(
                label: o,
                selected: value == o,
                onTap: () => setState(() => onPick(o)),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => MistyCard(
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTypography.title),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.md),
        MistyToggle(value: value, onChanged: onChanged),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final PresenceState presence = ref.watch(presenceProvider);
    _seed(ref.watch(settingsProvider).valueOrNull);
    const SizedBox gap = SizedBox(height: AppSizes.md);

    return ProfileSubPage(
      title: 'Availability Preferences',
      footer: MistyPrimaryButton(
        label: 'Save Preferences',
        isLoading: _saving,
        onPressed: _save,
      ),
      children: <Widget>[
        _choices(
          'Default session length',
          const <String>['30 min', '50 min', '60 min', '90 min'],
          _length,
          (String v) => _length = v,
        ),
        gap,
        _choices(
          'Break between sessions',
          const <String>['None', '10 min', '15 min', '30 min'],
          _buffer,
          (String v) => _buffer = v,
        ),
        gap,
        _choices(
          'Minimum booking notice',
          const <String>['1 hour', '4 hours', '12 hours', '24 hours'],
          _notice,
          (String v) => _notice = v,
        ),
        gap,
        _switch(
          'Accept Talk Now requests',
          'Instant requests during your availability',
          presence.acceptTalkNow,
          (bool v) => AppFeedback.guard(
            context,
            () => ref.read(presenceProvider.notifier).setAcceptTalkNow(v),
          ),
        ),
        gap,
        _switch(
          'Remind me to go online',
          'A nudge when a slot begins',
          _autoOnline,
          (bool v) => setState(() => _autoOnline = v),
        ),
        gap,
        _switch(
          'Open weekends',
          'Allow bookings on Saturday and Sunday',
          _weekends,
          (bool v) => setState(() => _weekends = v),
        ),
      ],
    );
  }
}
