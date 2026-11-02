import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../consultation_args.dart';

/// A gentle close to every consultation, with a private note field that is
/// saved to the session (only the psychologist ever sees it).
class SessionCompleteScreen extends ConsumerStatefulWidget {
  const SessionCompleteScreen({super.key, required this.summary});

  final SessionSummary summary;

  @override
  ConsumerState<SessionCompleteScreen> createState() =>
      _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen> {
  final TextEditingController _note = TextEditingController();
  bool _saving = false;

  SessionSummary get summary => widget.summary;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Saves the note (if any) before leaving; stays put if saving fails.
  Future<bool> _saveNote() async {
    final String note = _note.text.trim();
    final String? sessionId = summary.args.sessionId;
    if (note.isEmpty || sessionId == null) return true;
    setState(() => _saving = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(sessionsProvider.notifier).saveNotes(sessionId, note),
    );
    if (mounted) setState(() => _saving = false);
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final bool stillOnline = ref.watch(presenceProvider).isLive;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.xxxl,
                    AppSizes.screenPadding,
                    AppSizes.lg,
                  ),
                  children: <Widget>[
                    Center(
                      child: Image.asset(AppAssets.cloudCalm, height: 120),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    Text(
                      'Session complete',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'You held space for someone today. Take a moment for '
                      'yourself too.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSizes.xl),
                    MistyCard(
                      child: Column(
                        children: <Widget>[
                          MistyInfoRow(
                            label: 'Client',
                            value: summary.args.clientName,
                          ),
                          MistyInfoRow(
                            label: 'Mode',
                            value: summary.args.mode.label,
                          ),
                          MistyInfoRow(
                            label: 'Duration',
                            value: Fmt.clock(summary.duration),
                          ),
                          const Divider(height: AppSizes.xl),
                          MistyInfoRow(
                            label: 'Earned',
                            value: '+ ${Fmt.money(summary.earned)}',
                            valueColor: AppColors.mintInk,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    MistyTextField(
                      controller: _note,
                      label: 'Private session note (only you can see this)',
                      hint: 'Themes, techniques used, follow-ups…',
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.sm,
                  AppSizes.screenPadding,
                  AppSizes.lg,
                ),
                child: Column(
                  children: <Widget>[
                    MistyPrimaryButton(
                      label: stillOnline ? 'Back to Waiting' : 'Back to Home',
                      isLoading: _saving,
                      onPressed: () async {
                        if (!await _saveNote() || !context.mounted) return;
                        AppFeedback.toast(context, 'Session saved');
                        final GoRouter router = GoRouter.of(context);
                        router.go(AppRoutes.home);
                        if (stillOnline) router.push(AppRoutes.onlineWaiting);
                      },
                    ),
                    if (stillOnline) ...<Widget>[
                      const SizedBox(height: AppSizes.md),
                      MistySecondaryButton(
                        label: 'Go Offline',
                        onPressed: () async {
                          if (!await _saveNote() || !context.mounted) return;
                          final bool ok = await AppFeedback.guard(
                            context,
                            () =>
                                ref.read(presenceProvider.notifier).goOffline(),
                          );
                          if (ok && context.mounted) context.go(AppRoutes.home);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
