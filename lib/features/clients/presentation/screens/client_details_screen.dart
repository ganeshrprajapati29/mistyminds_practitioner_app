import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_session_card.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/session.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';

class ClientDetailsScreen extends ConsumerWidget {
  const ClientDetailsScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Client? c = ref.watch(clientByIdProvider(clientId));
    final List<Session> history = ref.watch(
      sessionsForClientProvider(clientId),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const MistyAppBar(title: 'Client'),
          Expanded(
            child: c == null
                ? const MistyEmptyState(
                    title: 'Client not found',
                    message: 'They may have closed their account.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      AppSizes.sm,
                      AppSizes.screenPadding,
                      AppSizes.xxl,
                    ),
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          MistyProfileAvatar(
                            name: c.name,
                            anonymous: c.anonymous,
                            size: 96,
                            ring: true,
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(c.name, style: AppTypography.displaySmall),
                          if (c.ageRange != null)
                            Text(
                              'Age ${c.ageRange}',
                              style: AppTypography.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xl),
                      Row(
                        children: <Widget>[
                          _Stat(value: '${c.sessionCount}', label: 'Sessions'),
                          const SizedBox(width: AppSizes.md),
                          _Stat(
                            value: Fmt.shortDate(c.firstSession),
                            label: 'Client since',
                          ),
                          const SizedBox(width: AppSizes.md),
                          _Stat(value: c.preferredMode.label, label: 'Prefers'),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),
                      MistyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Shared concerns', style: AppTypography.title),
                            const SizedBox(height: AppSizes.sm + 2),
                            Wrap(
                              spacing: AppSizes.sm,
                              runSpacing: AppSizes.sm,
                              children: <Widget>[
                                for (final String t in c.concerns)
                                  MistyChip(label: t),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (c.anonymous)
                        const MistyInfoNote(
                          text:
                              'This client chose to stay anonymous. Their '
                              'name, photo and contact details are never '
                              'shared.',
                          icon: Icons.visibility_off_outlined,
                          center: true,
                        )
                      else
                        MistyCard(
                          color: AppColors.lavender,
                          shadow: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Private note · only you',
                                    style: AppTypography.title,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                c.privateNote ??
                                    'No notes yet. Add one after your next '
                                        'session.',
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSizes.xl),
                      const MistySectionHeader(title: 'Session history'),
                      if (history.isEmpty)
                        Text(
                          'No sessions on record.',
                          style: AppTypography.bodySmall,
                        )
                      else
                        for (final Session s in history) ...<Widget>[
                          MistySessionCard(
                            session: s,
                            onTap: () =>
                                context.go(AppRoutes.sessionDetails(s.id)),
                          ),
                          const SizedBox(height: AppSizes.md),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MistyCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md + 2,
          horizontal: AppSizes.sm,
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
