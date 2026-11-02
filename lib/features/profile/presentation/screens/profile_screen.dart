import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_menu_tile.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/guide_video.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../../../guide/presentation/widgets/guide_video_tiles.dart';
import 'profile_info_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final bool ok = await AppFeedback.confirm(
      context,
      title: 'Log out?',
      message: 'You’ll go offline and need to log in again to see clients.',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Psychologist? p = ref.watch(profileProvider).valueOrNull;
    if (p == null) {
      return ref.watch(profileProvider).hasError
          ? Center(
              child: MistyErrorState(
                onRetry: () => ref.invalidate(profileProvider),
              ),
            )
          : const Center(child: CircularProgressIndicator());
    }
    final List<GuideVideo> videos = ref.watch(
      videosForPlacementProvider(VideoPlacement.profile),
    );

    Widget group(String title, List<Widget> tiles) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.xs, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.body(
                11.5,
                weight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
          ),
          MistyCard(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
            child: Column(children: tiles),
          ),
        ],
      ),
    );

    MistyMenuTile info(ProfileSection s, IconData icon, String subtitle) =>
        MistyMenuTile(
          title: s.title,
          subtitle: subtitle,
          icon: icon,
          onTap: () => context.push(AppRoutes.profileInfo(s)),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSizes.xxl),
        children: <Widget>[
          const MistyPageTitle(title: 'Profile'),
          Padding(
            padding: AppSizes.pageInsets,
            child: MistyCard(
              radius: AppSizes.radiusCard,
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      MistyProfileAvatar(
                        name: p.name,
                        photoUrl: p.photoUrl,
                        size: 76,
                        ring: true,
                      ),
                      const SizedBox(width: AppSizes.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(p.name, style: AppTypography.headingMedium),
                            Text(p.title, style: AppTypography.bodySmall),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Icon(
                                  p.registration.verified
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 16,
                                  color: AppColors.mint,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.registration.verified
                                      ? 'Verified partner'
                                      : 'Verification pending',
                                  style: AppTypography.body(
                                    12.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.mintInk,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () => context.push(AppRoutes.editProfile),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Row(
                    children: <Widget>[
                      // Per-mode rates are listed only when they differ from
                      // one another.
                      if (p.modeRates.values.toSet().length > 1)
                        for (final MapEntry<ConsultMode, double> r
                            in p.modeRates.entries)
                          _Metric(
                            value: '${Fmt.money(r.value)} / min',
                            label: r.key.label,
                          )
                      else
                        _Metric(
                          value: p.ratePerMinute > 0
                              ? '${Fmt.money(p.modeRates.values.firstOrNull ?? p.ratePerMinute)} / min'
                              : '-',
                          label: 'Rate per minute',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          group('Professional', <Widget>[
            info(
              ProfileSection.qualifications,
              Icons.school_outlined,
              '${p.qualifications.length} qualifications',
            ),
            info(
              ProfileSection.specializations,
              Icons.spa_outlined,
              p.specializations.take(3).join(', '),
            ),
            info(
              ProfileSection.registration,
              Icons.verified_outlined,
              'RCI · ${p.registration.number}',
            ),
            MistyMenuTile(
              title: 'Documents',
              subtitle: '${p.documents.length} files',
              icon: Icons.folder_open_rounded,
              onTap: () => context.push(AppRoutes.documents),
            ),
          ]),
          group('Practice', <Widget>[
            MistyMenuTile(
              title: 'My Sessions',
              subtitle: 'Upcoming, completed and cancelled',
              leading: const MistySvgIcon(AppAssets.iconSessions, size: 40),
              onTap: () => context.go(AppRoutes.sessions),
            ),
            MistyMenuTile(
              title: 'Availability Preferences',
              subtitle: 'Session length, buffers, Talk Now',
              leading: const MistySvgIcon(AppAssets.iconCalendar, size: 40),
              onTap: () => context.push(AppRoutes.availabilityPreferences),
            ),
            info(
              ProfileSection.bank,
              Icons.account_balance_outlined,
              '${p.bank.bank} ${p.bank.accountMasked.substring(p.bank.accountMasked.length - 4)}',
            ),
          ]),
          if (videos.isNotEmpty)
            group('Guides', <Widget>[
              for (final GuideVideo video in videos)
                GuideVideoTile(video: video),
            ]),
          group('Account', <Widget>[
            MistyMenuTile(
              title: 'Notifications',
              leading: const MistySvgIcon(AppAssets.iconNotification, size: 40),
              onTap: () => context.push(AppRoutes.notificationSettings),
            ),
            MistyMenuTile(
              title: 'Privacy',
              icon: Icons.shield_outlined,
              onTap: () => context.push(AppRoutes.privacy),
            ),
            MistyMenuTile(
              title: 'Help & Support',
              icon: Icons.support_agent_rounded,
              onTap: () => context.push(AppRoutes.help),
            ),
            MistyMenuTile(
              title: 'Logout',
              icon: Icons.logout_rounded,
              destructive: true,
              onTap: () => _logout(context, ref),
            ),
          ]),
          const SizedBox(height: AppSizes.xl),
          Center(
            child: Text(
              '${AppStrings.appTitle} · v1.0.0',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: const BoxDecoration(
          color: AppColors.lavender,
          borderRadius: AppSizes.brMd,
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: AppTypography.body(16, weight: FontWeight.w700),
            ),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
