import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../state/providers.dart';
import '../widgets/profile_sub_page.dart';
import '../widgets/support_sheet.dart';

enum ProfileSection {
  qualifications('Qualifications'),
  specializations('Specializations'),
  registration('Registration Details'),
  bank('Bank Details');

  const ProfileSection(this.title);
  final String title;
}

/// Read-only detail pages for the professional parts of the profile.
/// Changes go through the verification team, so each page offers a
/// "request an update" action rather than inline editing.
class ProfileInfoScreen extends ConsumerWidget {
  const ProfileInfoScreen({super.key, required this.section});

  final ProfileSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Psychologist? p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const Center(child: CircularProgressIndicator());

    final List<Widget> body = switch (section) {
      ProfileSection.qualifications => <Widget>[
        for (final Qualification q in p.qualifications)
          _Entry(
            icon: Icons.school_outlined,
            title: q.degree,
            lines: <String>[q.institution, '${q.year}'],
          ),
      ],
      ProfileSection.specializations => <Widget>[
        _ChipCard(title: 'Areas of focus', chips: p.specializations),
        const SizedBox(height: AppSizes.md),
        _ChipCard(title: 'Languages', chips: p.languages),
        const SizedBox(height: AppSizes.md),
        _ChipCard(
          title: 'Consultation modes',
          chips: p.modes.map((ConsultMode m) => m.label).toList(),
        ),
        const SizedBox(height: AppSizes.md),
        MistyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('About me', style: AppTypography.title),
              const SizedBox(height: AppSizes.sm),
              Text(p.bio, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
      ProfileSection.registration => <Widget>[
        MistyCard(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: MistyStatusChip(
                  label: p.registration.verified ? 'Verified' : 'Pending',
                  tone: p.registration.verified
                      ? ChipTone.mint
                      : ChipTone.amber,
                  dot: true,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              MistyInfoRow(label: 'Council', value: p.registration.council),
              MistyInfoRow(
                label: 'Registration no.',
                value: p.registration.number,
              ),
              MistyInfoRow(
                label: 'Valid till',
                value: p.registration.validTill,
              ),
            ],
          ),
        ),
      ],
      ProfileSection.bank => <Widget>[
        MistyCard(
          child: Column(
            children: <Widget>[
              MistyInfoRow(label: 'Account holder', value: p.bank.holder),
              MistyInfoRow(label: 'Bank', value: p.bank.bank),
              MistyInfoRow(label: 'Account', value: p.bank.accountMasked),
              MistyInfoRow(label: 'IFSC', value: p.bank.ifsc),
              MistyInfoRow(label: 'UPI', value: p.bank.upi),
              MistyInfoRow(label: 'PAN', value: p.bank.pan),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        const MistyInfoNote(
          text:
              'For your security, bank changes are verified with a small test '
              'deposit before payouts switch over.',
          icon: Icons.lock_outline_rounded,
        ),
      ],
    };

    return ProfileSubPage(
      title: section.title,
      footer: TextButton.icon(
        onPressed: () => showSupportSheet(
          context,
          title: 'Request an update',
          subtitle:
              'Tell us what should change in ${section.title.toLowerCase()}.',
          prefix: 'Profile update request — ${section.title}',
        ),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Request an update'),
      ),
      children: body,
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.icon, required this.title, required this.lines});

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: MistyCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppTypography.title),
                  for (final String l in lines)
                    Text(l, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.title, required this.chips});

  final String title;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return MistyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.title),
          const SizedBox(height: AppSizes.sm + 2),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: <Widget>[
              for (final String c in chips) MistyChip(label: c),
            ],
          ),
        ],
      ),
    );
  }
}
