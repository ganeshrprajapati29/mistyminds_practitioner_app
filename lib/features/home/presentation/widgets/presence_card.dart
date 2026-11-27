import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../core/widgets/misty_toggle.dart';
import '../../../../data/models/enums.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/app_content_provider.dart';
import '../../../../state/providers.dart';

/// "Currently Offline / Go online when you're ready…" with the toggle and the
/// "Go Online Now" button. Turns mint once the psychologist is live.
class PresenceCard extends ConsumerWidget {
  const PresenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PresenceState presence = ref.watch(presenceProvider);
    final PresenceController controller = ref.read(presenceProvider.notifier);
    final AppContent c = ref.watch(appContentProvider);
    String t(String key, String fallback) => c.text('dashboard', key, fallback);

    final (String title, String hint, Color dot) = switch (presence.status) {
      PresenceStatus.offline => (
        t('presence.offline.title', AppStrings.currentlyOffline),
        t('presence.offline.hint', AppStrings.offlineHint),
        AppColors.textTertiary,
      ),
      PresenceStatus.online => (
        t('presence.online.title', AppStrings.youreOnline),
        t('presence.online.hint', AppStrings.onlineHint),
        AppColors.online,
      ),
      PresenceStatus.paused => (
        t('presence.paused.title', AppStrings.availabilityPaused),
        t('presence.paused.hint', AppStrings.pausedHint),
        AppColors.amber,
      ),
    };

    Future<void> toggle(bool on) async {
      if (on) {
        // Going online always passes through the "Ready when you are" screen.
        context.push(AppRoutes.goOnline);
        return;
      }
      final bool ok = await AppFeedback.confirm(
        context,
        title: 'Go offline?',
        message: 'Clients won’t be able to send you Talk Now requests.',
        confirmLabel: 'Go Offline',
      );
      if (!ok || !context.mounted) return;
      await AppFeedback.guard(context, controller.goOffline);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: AppSizes.brCard,
        border: Border.all(
          color: presence.isOnline ? AppColors.mintBorder : Colors.transparent,
        ),
      ),
      child: MistyCard(
        radius: AppSizes.radiusCard,
        gradient: presence.isOnline ? AppColors.mintGradient : null,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
        ),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: PresenceDot(
                    color: dot,
                    size: 11,
                    pulse: presence.isOnline,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey<PresenceStatus>(presence.status),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.body(
                            16.5,
                            weight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hint,
                          style: AppTypography.body(
                            13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                MistyToggle.mint(
                  value: presence.isLive,
                  onChanged: toggle,
                  semanticLabel: 'Online',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            MistyPrimaryButton(
              label: presence.isLive
                  ? AppStrings.viewTalkNowStatus
                  : AppStrings.goOnlineNow,
              height: 50,
              onPressed: () => context.push(
                presence.isLive ? AppRoutes.onlineWaiting : AppRoutes.goOnline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
