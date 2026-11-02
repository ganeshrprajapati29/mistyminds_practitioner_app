import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_brand.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';

/// Wordmark with the notification bell, as in the reference.
class HomeBrandBar extends ConsumerWidget {
  const HomeBrandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationsProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(width: 44),
        const Expanded(child: Center(child: MistyWordmark(height: 56))),
        Semantics(
          button: true,
          label: 'Notifications, $unread unread',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(AppRoutes.notifications),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const MistySvgIcon(
                    AppAssets.iconNotification,
                    tile: false,
                    size: 26,
                    color: AppColors.textPrimary,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 9,
                      top: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Portrait, name, title and "View Profile ›".
class HomeIdentity extends StatelessWidget {
  const HomeIdentity({super.key, required this.profile});

  final Psychologist profile;

  @override
  Widget build(BuildContext context) {
    final double avatar = (MediaQuery.sizeOf(context).width * 0.23).clamp(
      76.0,
      96.0,
    );
    return Row(
      children: <Widget>[
        MistyProfileAvatar(
          name: profile.name,
          photoUrl: profile.photoUrl,
          size: avatar,
          ring: true,
        ),
        const SizedBox(width: AppSizes.lg + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  20,
                  weight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.title,
                style: AppTypography.body(14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () => context.go(AppRoutes.profile),
                borderRadius: AppSizes.brSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        AppStrings.viewProfile,
                        style: AppTypography.body(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
