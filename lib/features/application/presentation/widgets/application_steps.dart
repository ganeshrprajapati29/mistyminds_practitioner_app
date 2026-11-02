import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../data/models/enums.dart';
import '../../../../state/providers.dart';
import '../application_form.dart';

const SizedBox _gap = SizedBox(height: AppSizes.lg);

/// A label above a wrap of single- or multi-select chips.
class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<String> options;
  final bool Function(String) isSelected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSizes.sm + 2),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: <Widget>[
            for (final String o in options)
              MistyChip(
                label: o,
                selected: isSelected(o),
                onTap: () => onTap(o),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class PersonalStep extends StatelessWidget {
  const PersonalStep({super.key, required this.form, required this.onChanged});

  final ApplicationForm form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        MistyTextField(
          label: 'Full name',
          controller: form.name,
          hint: 'As on your registration certificate',
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (String? v) => Validators.required(v, 'Full name'),
        ),
        _gap,
        MistyTextField(
          label: 'Email',
          controller: form.email,
          hint: 'you@example.com',
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.emailOrPhone,
        ),
        _gap,
        MistyTextField(
          label: 'Mobile number',
          controller: form.phone,
          hint: '10-digit mobile',
          prefixIcon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          textInputAction: TextInputAction.next,
          validator: (String? v) =>
              (v ?? '').length == 10 ? null : 'Enter a 10-digit mobile number',
        ),
        _gap,
        MistyTextField(
          label: 'City',
          controller: form.city,
          hint: 'e.g. Mumbai',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        _gap,
        _ChoiceGroup(
          label: 'Gender',
          options: ApplicationForm.genders,
          isSelected: (String o) => form.gender == o,
          onTap: (String o) {
            form.gender = o;
            onChanged();
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class ProfessionalStep extends StatelessWidget {
  const ProfessionalStep({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ApplicationForm form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ChoiceGroup(
          label: 'Professional title',
          options: ApplicationForm.titles,
          isSelected: (String o) => form.title == o,
          onTap: (String o) {
            form.title = o;
            onChanged();
          },
        ),
        _gap,
        MistyTextField(
          label: 'Highest qualification',
          controller: form.degree,
          hint: 'e.g. M.Phil. Clinical Psychology',
          prefixIcon: Icons.school_outlined,
          validator: (String? v) => Validators.required(v, 'Qualification'),
        ),
        _gap,
        MistyTextField(
          label: 'Institution',
          controller: form.institution,
          hint: 'University / institute',
          prefixIcon: Icons.account_balance_outlined,
        ),
        _gap,
        MistyTextField(
          label: 'Year of completion',
          controller: form.graduationYear,
          hint: 'YYYY',
          prefixIcon: Icons.event_outlined,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        _gap,
        MistyTextField(
          label: 'Current workplace (optional)',
          controller: form.workplace,
          hint: 'Hospital, clinic or private practice',
          prefixIcon: Icons.work_outline_rounded,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class PracticeStep extends StatelessWidget {
  const PracticeStep({super.key, required this.form, required this.onChanged});

  final ApplicationForm form;
  final VoidCallback onChanged;

  void _toggle(Set<String> set, String value) {
    set.contains(value) ? set.remove(value) : set.add(value);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ChoiceGroup(
          label: 'Specialisations (choose all that apply)',
          options: ApplicationForm.allSpecializations,
          isSelected: form.specializations.contains,
          onTap: (String o) => _toggle(form.specializations, o),
        ),
        _gap,
        _ChoiceGroup(
          label: 'Languages you consult in',
          options: ApplicationForm.allLanguages,
          isSelected: form.languages.contains,
          onTap: (String o) => _toggle(form.languages, o),
        ),
        _gap,
        Text('Consultation modes', style: AppTypography.label),
        const SizedBox(height: AppSizes.sm + 2),
        Row(
          children: <Widget>[
            for (final ConsultMode m in ConsultMode.values) ...<Widget>[
              Expanded(
                child: _ModeTile(
                  mode: m,
                ),
              ),
              if (m != ConsultMode.values.last)
                const SizedBox(width: AppSizes.sm + 2),
            ],
          ],
        ),
        _gap,
        MistyTextField(
          label: 'A short introduction for clients',
          controller: form.bio,
          hint:
              'How you work, who you help, and what a first session with you '
              'feels like.',
          maxLines: 4,
          maxLength: 400,
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
  });

  final ConsultMode mode;

  @override
  Widget build(BuildContext context) {
    return MistyCard(
      shadow: false,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      borderColor: AppColors.primary,
      color: AppColors.primarySoft,
      child: Column(
        children: <Widget>[
          MistySvgIcon(mode.icon, size: 40),
          const SizedBox(height: AppSizes.xs),
          Text(
            mode.label,
            style: AppTypography.body(
              13.5,
              weight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class RegistrationStep extends StatelessWidget {
  const RegistrationStep({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ApplicationForm form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: form.registrationUnavailable,
          title: const Text(
            "I don't have a registration / licence number yet",
          ),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (bool? value) {
            form.registrationUnavailable = value ?? false;
            onChanged();
          },
        ),
        if (form.registrationUnavailable)
          const MistyInfoNote(
            text:
                'No problem — you can continue without it. Our verification '
                'team will follow up with you about your registration, and '
                'you won’t be asked for the licence certificate.',
            icon: Icons.info_outline_rounded,
          )
        else ...<Widget>[
        _ChoiceGroup(
          label: 'Registering body',
          options: ApplicationForm.councils,
          isSelected: (String o) => form.council == o,
          onTap: (String o) {
            form.council = o;
            onChanged();
          },
        ),
        _gap,
        MistyTextField(
          label: 'Registration / licence number',
          controller: form.registrationNumber,
          hint: 'e.g. A43127',
          prefixIcon: Icons.verified_outlined,
          textCapitalization: TextCapitalization.characters,
          validator: (String? v) =>
              Validators.required(v, 'Registration number'),
        ),
        _gap,
        MistyTextField(
          label: 'Valid till',
          controller: form.validTill,
          hint: 'Select date',
          prefixIcon: Icons.event_available_outlined,
          readOnly: true,
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime? d = await showDatePicker(
              context: context,
              firstDate: now,
              lastDate: DateTime(now.year + 15),
              initialDate: DateTime(now.year + 3, now.month),
            );
            if (d != null) {
              form.validTill.text = '${d.day}/${d.month}/${d.year}';
              onChanged();
            }
          },
        ),
        _gap,
        const MistyInfoNote(
          text:
              'We verify every registration directly with the issuing body. '
              'This usually takes 2–3 working days.',
        ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class DocumentsStep extends ConsumerStatefulWidget {
  const DocumentsStep({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ApplicationForm form;
  final VoidCallback onChanged;

  @override
  ConsumerState<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends ConsumerState<DocumentsStep> {
  /// Documents currently uploading.
  final Set<String> _uploading = <String>{};

  ApplicationForm get form => widget.form;

  Future<void> _upload(String name) async {
    final PickedFile? file = await pickDocument(context);
    if (file == null || !mounted) return;
    setState(() => _uploading.add(name));
    String? reference;
    final bool ok = await AppFeedback.guard(context, () async {
      reference = await ref
          .read(repositoryProvider)
          .uploadApplicationDocument(file.bytes, file.name);
    });
    if (!mounted) return;
    setState(() => _uploading.remove(name));
    if (ok && reference != null) {
      form.documents[name] = reference!;
      form.documentNames[name] = file.name;
      widget.onChanged();
      AppFeedback.toast(context, '$name uploaded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ...<Widget>[
          for (final (String name, bool required)
              in ApplicationForm.requiredDocuments) ...<Widget>[
            _DocumentTile(
              name: name,
              required: form.isRequired(name, required),
              fileName: _uploading.contains(name)
                  ? 'Uploading…'
                  : form.documentNames[name] ??
                        (form.documents.containsKey(name) ? 'Uploaded' : null),
              onUpload: () {
                if (!_uploading.contains(name)) _upload(name);
              },
              onRemove: () {
                form.documents.remove(name);
                form.documentNames.remove(name);
                widget.onChanged();
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
          const MistyInfoNote(
            text:
                'Your professional photo is compulsory. PDF, JPG or PNG up to '
                '5 MB each. Documents are sent securely, never made public, '
                'and only seen by our verification team.',
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.name,
    required this.required,
    required this.fileName,
    required this.onUpload,
    required this.onRemove,
  });

  final String name;
  final bool required;
  final String? fileName;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool done = fileName != null;
    return MistyCard(
      padding: const EdgeInsets.all(AppSizes.md + 2),
      borderColor: done ? AppColors.mintBorder : AppColors.border,
      shadow: false,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done ? AppColors.mintSoft : AppColors.lavender,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.description_outlined,
              color: done ? AppColors.mintInk : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: AppTypography.title),
                const SizedBox(height: 2),
                Text(
                  done ? fileName! : (required ? 'Required' : 'Optional'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          if (done)
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textTertiary,
              ),
            )
          else
            TextButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: const Text('Upload'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class BankStep extends StatelessWidget {
  const BankStep({super.key, required this.form});

  final ApplicationForm form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MistyTextField(
          label: 'Account holder name',
          controller: form.accountHolder,
          hint: 'As on bank records',
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          validator: (String? v) => Validators.required(v, 'Account holder'),
        ),
        _gap,
        MistyTextField(
          label: 'Bank name',
          controller: form.bankName,
          hint: 'e.g. HDFC Bank',
          prefixIcon: Icons.account_balance_outlined,
        ),
        _gap,
        MistyTextField(
          label: 'Account number',
          controller: form.accountNumber,
          hint: 'Account number',
          prefixIcon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (String? v) =>
              (v ?? '').length < 9 ? 'Enter a valid account number' : null,
        ),
        _gap,
        MistyTextField(
          label: 'IFSC',
          controller: form.ifsc,
          hint: 'e.g. HDFC0000240',
          prefixIcon: Icons.qr_code_rounded,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
        ),
        _gap,
        MistyTextField(
          label: 'UPI ID (optional)',
          controller: form.upi,
          hint: 'name@bank',
          prefixIcon: Icons.bolt_rounded,
        ),
        _gap,
        MistyTextField(
          label: 'PAN',
          controller: form.pan,
          hint: 'ABCDE1234F',
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.form,
    required this.onEdit,
    required this.onChanged,
  });

  final ApplicationForm form;
  final ValueChanged<int> onEdit;
  final VoidCallback onChanged;

  String _or(String v) => v.trim().isEmpty ? '—' : v.trim();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ReviewCard(
          title: 'Personal details',
          onEdit: () => onEdit(0),
          rows: <(String, String)>[
            ('Name', _or(form.name.text)),
            ('Email', _or(form.email.text)),
            ('Mobile', _or(form.phone.text)),
            ('City', _or(form.city.text)),
          ],
        ),
        _ReviewCard(
          title: 'Professional details',
          onEdit: () => onEdit(1),
          rows: <(String, String)>[
            ('Title', form.title),
            ('Qualification', _or(form.degree.text)),
          ],
        ),
        _ReviewCard(
          title: 'Practice',
          onEdit: () => onEdit(2),
          rows: <(String, String)>[
            (
              'Specialisations',
              form.specializations.isEmpty
                  ? '—'
                  : form.specializations.join(', '),
            ),
            ('Languages', form.languages.join(', ')),
            (
              'Modes',
              ApplicationForm.compulsoryModes
                  .map((ConsultMode m) => m.label)
                  .join(', '),
            ),
          ],
        ),
        _ReviewCard(
          title: 'Registration',
          onEdit: () => onEdit(3),
          rows: <(String, String)>[
            ('Body', form.council),
            if (form.registrationUnavailable)
              ('Number', 'Not available yet')
            else ...<(String, String)>[
              ('Number', _or(form.registrationNumber.text)),
              ('Valid till', _or(form.validTill.text)),
            ],
          ],
        ),
        _ReviewCard(
          title: 'Documents',
          onEdit: () => onEdit(4),
          trailing: MistyStatusChip(
            label: form.documentsComplete ? 'Complete' : 'Incomplete',
            tone: form.documentsComplete ? ChipTone.mint : ChipTone.amber,
          ),
          rows: <(String, String)>[
            (
              'Status',
              '${form.documents.length} files uploaded',
            ),
          ],
        ),
        _ReviewCard(
          title: 'Bank details',
          onEdit: () => onEdit(5),
          rows: <(String, String)>[
            ('Account holder', _or(form.accountHolder.text)),
            ('Bank', _or(form.bankName.text)),
            (
              'Account',
              form.accountNumber.text.length > 4
                  ? '•••• ${form.accountNumber.text.substring(form.accountNumber.text.length - 4)}'
                  : '—',
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        InkWell(
          borderRadius: AppSizes.brMd,
          onTap: () {
            form.consent = !form.consent;
            onChanged();
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: form.consent,
                onChanged: (_) {
                  form.consent = !form.consent;
                  onChanged();
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'I confirm these details are accurate and agree to the '
                    'MistyMinds: Practitioner Code of Conduct and client '
                    'confidentiality policy.',
                    style: AppTypography.bodySmall,
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.rows,
    required this.onEdit,
    this.trailing,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: MistyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(title, style: AppTypography.headingSmall)),
                ?trailing,
                const SizedBox(width: AppSizes.xs),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            for (final (String label, String value) in rows)
              MistyInfoRow(label: label, value: value),
          ],
        ),
      ),
    );
  }
}
