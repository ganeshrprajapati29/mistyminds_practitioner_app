import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../core/widgets/misty_toggle.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/remaining_time_card.dart';

/// "Ready when you are." — the third reference screen.
class GoOnlineScreen extends ConsumerStatefulWidget {
  const GoOnlineScreen({super.key});

  @override
  ConsumerState<GoOnlineScreen> createState() => _GoOnlineScreenState();
}

class _GoOnlineScreenState extends ConsumerState<GoOnlineScreen> {
  /// Armed by the "Go Online" switch; confirmed by "I'm Online Now".
  bool _ready = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Today's window comes from the psychologist's saved availability.
    Future<void>.microtask(() => ref.read(presenceProvider.notifier).refresh());
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(presenceProvider.notifier).goOnline(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pushReplacement(AppRoutes.onlineWaiting);
  }

  @override
  Widget build(BuildContext context) {
    final PresenceState presence = ref.watch(presenceProvider);
    final bool compact = MediaQuery.sizeOf(context).height < 720;

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const MistyAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                0,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              children: <Widget>[
                Center(
                  child: Image.asset(
                    AppAssets.cloudReady,
                    height: compact ? 104 : 128,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  AppStrings.readyTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                Text.rich(
                  TextSpan(
                    text: '${AppStrings.readySubtitle} ',
                    children: const <InlineSpan>[
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: AppColors.lilacHeart,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.xl),
                _GoOnlineCard(
                  value: _ready,
                  onChanged: (bool v) => setState(() => _ready = v),
                ),
                const SizedBox(height: AppSizes.md + 2),
                RemainingTimeCard(window: presence.window),
                const SizedBox(height: AppSizes.md + 2),
                MistyCard(
                  radius: AppSizes.radiusCard,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppStrings.acceptTalkNow,
                              style: AppTypography.body(
                                15.5,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.acceptTalkNowHint,
                              style: AppTypography.body(
                                13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      MistyToggle(
                        value: presence.acceptTalkNow,
                        onChanged: (bool v) => AppFeedback.guard(
                          context,
                          () => ref
                              .read(presenceProvider.notifier)
                              .setAcceptTalkNow(v),
                        ),
                        semanticLabel: AppStrings.acceptTalkNow,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md + 2),
                const MistyInfoNote(text: AppStrings.keepAppOpen, center: true),
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
              label: AppStrings.imOnlineNow,
              isLoading: _busy,
              onPressed: _ready ? _confirm : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoOnlineCard extends StatelessWidget {
  const _GoOnlineCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg + 2,
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.lg + 2,
      ),
      decoration: BoxDecoration(
        gradient: value ? AppColors.mintGradient : null,
        color: value ? null : AppColors.surface,
        borderRadius: AppSizes.brCard,
        border: Border.all(
          color: value ? AppColors.mintBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              PresenceDot(
                color: value ? AppColors.online : AppColors.textTertiary,
                size: 13,
                pulse: value,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  AppStrings.goOnline,
                  style: AppTypography.body(19, weight: FontWeight.w600),
                ),
              ),
              MistyToggle.mint(
                value: value,
                onChanged: onChanged,
                semanticLabel: AppStrings.goOnline,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            AppStrings.goOnlineHint,
            textAlign: TextAlign.center,
            style: AppTypography.body(13.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
