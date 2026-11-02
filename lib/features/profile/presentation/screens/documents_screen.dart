import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../state/providers.dart';
import '../widgets/profile_sub_page.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Psychologist? p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const Center(child: CircularProgressIndicator());

    return ProfileSubPage(
      title: 'Documents',
      children: <Widget>[
        const MistyInfoNote(
          text:
              'Documents are encrypted and visible only to the Misty Minds '
              'verification team.',
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSizes.lg),
        for (final ProfessionalDocument d in p.documents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: MistyCard(
              padding: const EdgeInsets.all(AppSizes.md + 2),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(d.name, style: AppTypography.title),
                        const SizedBox(height: 2),
                        Text(
                          d.fileName ?? 'Tap to upload',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        MistyStatusChip(
                          label: d.status.label,
                          tone: switch (d.status) {
                            DocumentStatus.verified => ChipTone.mint,
                            DocumentStatus.underReview => ChipTone.amber,
                            DocumentStatus.missing => ChipTone.coral,
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: d.fileName == null ? 'Upload' : 'Replace',
                    onPressed: d.status == DocumentStatus.verified
                        ? null
                        : () => _upload(context, ref, d.name),
                    icon: Icon(
                      d.fileName == null
                          ? Icons.upload_rounded
                          : Icons.sync_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// PDF or photo → upload → the document shows as "under review".
Future<void> _upload(BuildContext context, WidgetRef ref, String name) async {
  final PickedFile? file = await pickDocument(context);
  if (file == null || !context.mounted) return;
  AppFeedback.toast(context, 'Uploading ${file.name}…');
  final bool ok = await AppFeedback.guard(
    context,
    () => ref
        .read(profileProvider.notifier)
        .uploadDocument(name, file.bytes, file.name),
  );
  if (ok && context.mounted) {
    AppFeedback.toast(context, 'Uploaded — our team will review it shortly.');
  }
}
