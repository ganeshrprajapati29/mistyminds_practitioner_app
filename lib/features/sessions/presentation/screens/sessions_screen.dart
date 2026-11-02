import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_segmented_control.dart';
import '../../../../core/widgets/misty_session_card.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/session.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';

/// Upcoming / Completed / Cancelled sessions.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  late int _tab = widget.initialTab.clamp(0, 2);

  static const List<SessionStatus> _tabs = <SessionStatus>[
    SessionStatus.upcoming,
    SessionStatus.completed,
    SessionStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Session>> all = ref.watch(sessionsProvider);
    final bool loading = all.isLoading && !all.hasValue;
    final bool failed = all.hasError && !all.hasValue;
    final List<Session> list = ref.watch(sessionsByStatusProvider(_tabs[_tab]));

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const MistyAppBar(title: 'Sessions'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.sm,
              AppSizes.screenPadding,
              AppSizes.md,
            ),
            child: MistySegmentedControl(
              segments: const <String>['Upcoming', 'Completed', 'Cancelled'],
              selected: _tab,
              onChanged: (int i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : failed
                  ? MistyErrorState(
                      onRetry: () => ref.invalidate(sessionsProvider),
                    )
                  : list.isEmpty
                  ? MistyEmptyState(
                      key: ValueKey<int>(_tab),
                      title: switch (_tabs[_tab]) {
                        SessionStatus.upcoming => 'A quiet schedule',
                        SessionStatus.completed => 'No completed sessions yet',
                        SessionStatus.cancelled => 'Nothing cancelled',
                      },
                      message: _tabs[_tab] == SessionStatus.upcoming
                          ? 'Open more availability so clients can book you.'
                          : 'Sessions will appear here as they happen.',
                      image: AppAssets.cloudCalm,
                    )
                  : ListView.separated(
                      key: ValueKey<int>(_tab),
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.screenPadding,
                        AppSizes.xs,
                        AppSizes.screenPadding,
                        AppSizes.xxl,
                      ),
                      itemCount: list.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.md),
                      itemBuilder: (BuildContext context, int i) {
                        if (i == 0) {
                          return Text(
                            '${list.length} ${_tabs[_tab].label.toLowerCase()} '
                            '${list.length == 1 ? 'session' : 'sessions'}',
                            style: AppTypography.bodySmall,
                          );
                        }
                        final Session s = list[i - 1];
                        return MistySessionCard(
                          session: s,
                          onTap: () =>
                              context.push(AppRoutes.sessionDetails(s.id)),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
