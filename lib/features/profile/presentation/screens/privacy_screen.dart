import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_menu_tile.dart';
import '../../../../core/widgets/misty_toggle.dart';
import '../../../../data/models/settings.dart';
import '../../../../state/app_content_provider.dart';
import '../../../../state/providers.dart';
import '../widgets/profile_sub_page.dart';

const String _defaultPolicyTitle = 'Client confidentiality';
const String _defaultFooter =
    'Session notes are private to you and are never shared with '
    'clients or other partners.';
const List<String> _defaultPolicy = <String>[
  'Everything a client shares in a session stays between you and '
      'them, except where the law or imminent risk of harm '
      'requires otherwise.',
  'Never record, screenshot or share session content outside '
      'Misty Minds.',
  'Anonymous clients must never be asked to reveal their '
      'identity.',
  'If you believe a client is at risk, use the in-session '
      'safety escalation and follow the partner safety protocol.',
];

/// Privacy switches, saved to the practitioner's account.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  void _set(String key, bool value) => AppFeedback.guard(
    context,
    () => ref.read(settingsProvider.notifier).setPrivacy(key, value),
  );

  Widget _row(String title, String sub, bool v, ValueChanged<bool> on) =>
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
                  Text(sub, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.md),
            MistyToggle(value: v, onChanged: on),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Map<String, bool> privacy =
        (ref.watch(settingsProvider).valueOrNull ??
                PractitionerSettings.defaults)
            .privacy;
    final bool showPhoto = privacy['showPhoto'] ?? true;
    final bool appLock = privacy['appLock'] ?? false;
    final bool hidePreviews = privacy['hidePreviews'] ?? true;
    // Admin console → App content → Client confidentiality policy.
    final ContentDocument? policy = ref
        .watch(appContentProvider)
        .document('confidentiality');

    return ProfileSubPage(
      title: 'Privacy',
      children: <Widget>[
        MistyCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xs,
          ),
          child: Column(
            children: <Widget>[
              _row(
                'Show my photo to clients',
                'Otherwise clients see your initials',
                showPhoto,
                (bool v) => _set('showPhoto', v),
              ),
              const Divider(),
              _row(
                'App lock',
                'Require fingerprint or PIN to open',
                appLock,
                (bool v) => _set('appLock', v),
              ),
              const Divider(),
              _row(
                'Hide message previews',
                'Keep client messages off the lock screen',
                hidePreviews,
                (bool v) => _set('hidePreviews', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MistyCard(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          child: Column(
            children: <Widget>[
              MistyMenuTile(
                title: 'Client confidentiality policy',
                icon: Icons.policy_outlined,
                onTap: () => _policy(context, policy),
              ),
              MistyMenuTile(
                title: 'Download my data',
                icon: Icons.download_rounded,
                onTap: () => _requestExport(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MistyInfoNote(
          text: policy != null && policy.footer.isNotEmpty
              ? policy.footer
              : _defaultFooter,
          icon: Icons.lock_outline_rounded,
        ),
      ],
    );
  }

  void _policy(BuildContext context, ContentDocument? policy) {
    final List<ContentSection> sections =
        policy?.sections ??
        _defaultPolicy
            .map((String p) => ContentSection(heading: '', body: p))
            .toList();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (BuildContext context, ScrollController c) => ListView(
          controller: c,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            0,
            AppSizes.screenPadding,
            AppSizes.xxl,
          ),
          children: <Widget>[
            Text(
              policy != null && policy.title.isNotEmpty
                  ? policy.title
                  : _defaultPolicyTitle,
              style: AppTypography.displaySmall,
            ),
            if (policy != null && policy.intro.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSizes.sm),
              Text(policy.intro, style: AppTypography.bodyMedium),
            ],
            const SizedBox(height: AppSizes.md),
            for (final ContentSection p in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (p.heading.isNotEmpty)
                      Text(p.heading, style: AppTypography.title),
                    if (p.body.isNotEmpty)
                      Text(p.body, style: AppTypography.bodyMedium),
                    if (p.hasLink)
                      TextButton.icon(
                        onPressed: () => openContentLink(p.linkUrl),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(
                          p.linkLabel.isEmpty ? 'Open link' : p.linkLabel,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Files a data-export request with the partner team (a support ticket in
/// the privacy queue); the export is emailed to the registered address.
Future<void> _requestExport(BuildContext context, WidgetRef ref) async {
  String? reference;
  final bool ok = await AppFeedback.guard(context, () async {
    reference = await ref
        .read(repositoryProvider)
        .contactSupport(
          'Please send me an export of all my partner data.',
          category: 'privacy',
        );
  });
  if (ok && context.mounted) {
    AppFeedback.toast(
      context,
      'Request sent (ref $reference). We’ll email your data within 48 hours.',
    );
  }
}
