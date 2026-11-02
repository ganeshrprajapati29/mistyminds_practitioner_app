import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_menu_tile.dart';
import '../../../../data/models/guide_video.dart';
import '../../../../state/providers.dart';
import '../../../guide/presentation/widgets/guide_video_tiles.dart';
import '../widgets/profile_sub_page.dart';
import '../widgets/support_sheet.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const List<(String, String)> _faqs = <(String, String)>[
    (
      'How does Talk Now work?',
      'When you go online inside an availability window, clients who choose '
          '“Talk to someone now” can send you a request. You can accept or '
          'decline — declining never affects your rating.',
    ),
    (
      'Why a 2-hour minimum per day?',
      'It gives clients a meaningful window to book you and keeps your '
          'profile visible in search.',
    ),
    (
      'What if a client is in crisis?',
      'Use the safety escalation in the session menu. Our crisis team joins '
          'within minutes and local emergency contacts are shared with you.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<GuideVideo> videos = ref.watch(
      videosForPlacementProvider(VideoPlacement.help),
    );
    return ProfileSubPage(
      title: 'Help & Support',
      children: <Widget>[
        MistyCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppSizes.brLg,
            child: Image.asset(
              AppAssets.cloudListening,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text('We’re here for you too.', style: AppTypography.displaySmall),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Our partner team replies within a few hours, every day.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSizes.lg),
        MistyCard(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          child: Column(
            children: <Widget>[
              MistyMenuTile(
                title: 'Chat with partner support',
                subtitle: 'We reply by email, usually the same day',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => showSupportSheet(
                  context,
                  title: 'Message partner support',
                  subtitle:
                      'Payouts, sessions, your profile — anything at all.',
                ),
              ),
              MistyMenuTile(
                title: 'Email us',
                subtitle: 'partners@mistyminds.in',
                icon: Icons.mail_outline_rounded,
                onTap: () => _email(context),
              ),
              MistyMenuTile(
                title: 'Clinical supervision',
                subtitle: 'Book a peer supervision slot',
                icon: Icons.psychology_alt_outlined,
                onTap: () => showSupportSheet(
                  context,
                  title: 'Request clinical supervision',
                  subtitle:
                      'Tell us what you’d like to discuss and when suits you.',
                  hint: 'e.g. A complex case, weekday evenings',
                  prefix: 'Clinical supervision request',
                ),
              ),
            ],
          ),
        ),
        if (videos.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSizes.xl),
          const MistySectionHeader(title: 'Video guides'),
          MistyCard(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
            child: Column(
              children: <Widget>[
                for (final GuideVideo video in videos)
                  GuideVideoTile(video: video),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSizes.xl),
        const MistySectionHeader(title: 'Frequently asked'),
        MistyCard(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: <Widget>[
                for (final (String q, String a) in _faqs)
                  ExpansionTile(
                    title: Text(q, style: AppTypography.title),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textTertiary,
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      0,
                      AppSizes.lg,
                      AppSizes.lg,
                    ),
                    children: <Widget>[
                      Text(a, style: AppTypography.bodyMedium),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _email(BuildContext context) async {
  final bool opened = await launchUrl(
    Uri(
      scheme: 'mailto',
      path: 'partners@mistyminds.in',
      queryParameters: <String, String>{
        'subject': 'MistyMinds partner support',
      },
    ),
  );
  if (!opened && context.mounted) {
    AppFeedback.toast(context, 'Write to us at partners@mistyminds.in');
  }
}
