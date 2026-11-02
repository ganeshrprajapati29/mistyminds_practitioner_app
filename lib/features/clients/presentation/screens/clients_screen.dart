import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/client.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Client>> async = ref.watch(clientsProvider);
    final List<Client> all = async.valueOrNull ?? const <Client>[];
    final List<Client> recent =
        (List<Client>.of(all)..sort(
              (Client a, Client b) => b.lastSession.compareTo(a.lastSession),
            ))
            .take(5)
            .toList();
    final String q = _query.trim().toLowerCase();
    final List<Client> filtered = all
        .where(
          (Client c) =>
              q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.concerns.any((String x) => x.toLowerCase().contains(q)),
        )
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSizes.xxl),
        children: <Widget>[
          MistyPageTitle(
            title: 'Clients',
            subtitle: '${all.length} people you’ve supported',
            trailing: const MistySvgIcon(AppAssets.iconClients, size: 52),
          ),
          Padding(
            padding: AppSizes.pageInsets,
            child: TextField(
              onChanged: (String v) => setState(() => _query = v),
              style: AppTypography.body(15),
              decoration: const InputDecoration(
                hintText: 'Search by name or concern',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          const Padding(
            padding: AppSizes.pageInsets,
            child: MistyInfoNote(
              text: AppStrings.privacyNote,
              icon: Icons.shield_outlined,
              center: true,
            ),
          ),
          if (q.isEmpty && recent.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSizes.xl),
            const Padding(
              padding: AppSizes.pageInsets,
              child: MistySectionHeader(title: 'Recent'),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                padding: AppSizes.pageInsets,
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSizes.lg),
                itemBuilder: (BuildContext context, int i) {
                  final Client c = recent[i];
                  return GestureDetector(
                    onTap: () => context.push(AppRoutes.clientDetails(c.id)),
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        children: <Widget>[
                          MistyProfileAvatar(
                            name: c.name,
                            anonymous: c.anonymous,
                            size: 60,
                            ring: true,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.anonymous ? 'Anonymous' : c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(
                              12,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          Padding(
            padding: AppSizes.pageInsets,
            child: MistySectionHeader(
              title: q.isEmpty ? 'All clients' : 'Results',
            ),
          ),
          if (async.hasError && !async.hasValue)
            MistyErrorState(onRetry: () => ref.invalidate(clientsProvider))
          else if (async.isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            const MistyEmptyState(
              title: 'No matches',
              message: 'Try a different name or concern.',
            )
          else
            for (final Client c in filtered)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  0,
                  AppSizes.screenPadding,
                  AppSizes.md,
                ),
                child: _ClientTile(client: c),
              ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final Client c = client;
    return MistyCard(
      onTap: () => context.push(AppRoutes.clientDetails(c.id)),
      padding: const EdgeInsets.all(AppSizes.md + 2),
      child: Row(
        children: <Widget>[
          MistyProfileAvatar(name: c.name, anonymous: c.anonymous, size: 50),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(c.name, style: AppTypography.title),
                const SizedBox(height: 2),
                Text(
                  '${c.sessionCount} ${c.sessionCount == 1 ? 'session' : 'sessions'}'
                  ' · Last ${Fmt.shortDate(c.lastSession)}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final String t in c.concerns)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: AppSizes.brPill,
                        ),
                        child: Text(
                          t,
                          style: AppTypography.body(
                            11.5,
                            weight: FontWeight.w500,
                            color: AppColors.primaryStrong,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          MistySvgIcon(c.preferredMode.icon, tile: false, size: 20),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
