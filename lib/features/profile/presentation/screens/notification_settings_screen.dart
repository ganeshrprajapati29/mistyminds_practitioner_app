import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_toggle.dart';
import '../../../../data/models/settings.dart';
import '../../../../state/providers.dart';
import '../widgets/profile_sub_page.dart';

/// Notification preferences, saved to the practitioner's account.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  /// (settings key, title, subtitle)
  static const List<(String, String, String)> _rows =
      <(String, String, String)>[
        ('talkRequests', 'Talk Now requests', 'Always on while you’re online'),
        ('newBookings', 'New bookings', 'When a client books a session'),
        (
          'sessionReminders',
          'Session reminders',
          '15 minutes before each session',
        ),
        (
          'availabilityEnding',
          'Availability ending',
          'When your window is about to close',
        ),
        ('payments', 'Payments', 'Settlements and payout updates'),
        ('tips', 'Tips & updates', 'Occasional product news'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PractitionerSettings settings =
        ref.watch(settingsProvider).valueOrNull ??
        PractitionerSettings.defaults;

    return ProfileSubPage(
      title: 'Notifications',
      children: <Widget>[
        MistyCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xs,
          ),
          child: Column(
            children: <Widget>[
              for (final (String key, String title, String subtitle)
                  in _rows) ...<Widget>[
                if (key != _rows.first.$1) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
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
                      MistyToggle(
                        value: settings.notifications[key] ?? true,
                        // Talk Now alerts cannot be muted while online.
                        onChanged: key == 'talkRequests'
                            ? null
                            : (bool v) => AppFeedback.guard(
                                context,
                                () => ref
                                    .read(settingsProvider.notifier)
                                    .setNotification(key, v),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
