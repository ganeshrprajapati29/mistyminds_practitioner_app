import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/app_notification.dart';
import '../../../../data/models/enums.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(notificationsProvider.notifier).markRead(n.id);
    switch (n.kind) {
      case NotificationKind.talkRequest:
      case NotificationKind.availabilityEnding:
        context.push(AppRoutes.goOnline);
      case NotificationKind.sessionBooked:
      case NotificationKind.sessionReminder:
        context.push(AppRoutes.sessions);
      case NotificationKind.paymentReceived:
        context.go(AppRoutes.earnings);
      case NotificationKind.general:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AppNotification> items =
        ref.watch(notificationsProvider).valueOrNull ??
        const <AppNotification>[];
    final int unread = ref.watch(unreadNotificationsProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          MistyAppBar(
            title: 'Notifications',
            trailing: unread == 0
                ? null
                : TextButton(
                    onPressed: ref
                        .read(notificationsProvider.notifier)
                        .markAllRead,
                    child: const Text('Read all'),
                  ),
          ),
          Expanded(
            child: ref.watch(notificationsProvider).hasError && items.isEmpty
                ? MistyErrorState(
                    onRetry: () => ref.invalidate(notificationsProvider),
                  )
                : items.isEmpty
                ? const MistyEmptyState(
                    title: 'All caught up',
                    message: 'New bookings and requests will show up here.',
                    image: AppAssets.cloudCalm,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      AppSizes.sm,
                      AppSizes.screenPadding,
                      AppSizes.xxl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizes.sm + 2),
                    itemBuilder: (BuildContext context, int i) {
                      final AppNotification n = items[i];
                      return _NotificationTile(
                        n: n,
                        onTap: () => _open(context, ref, n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: n.read ? AppColors.surface : AppColors.primarySoft,
        borderRadius: AppSizes.brLg,
        border: Border.all(
          color: n.read ? AppColors.border : AppColors.lavenderStrong,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSizes.brLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MistySvgIcon(n.kind.icon, size: 46),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              n.title,
                              style: AppTypography.body(
                                15,
                                weight: n.read
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(Fmt.ago(n.time), style: AppTypography.caption),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(n.body, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                if (!n.read) ...<Widget>[
                  const SizedBox(width: AppSizes.sm),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
