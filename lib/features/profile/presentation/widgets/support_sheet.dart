import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../state/providers.dart';

/// A message to the partner-support team, filed as a support ticket. The
/// team replies by email; the partner gets a reference number right away.
Future<void> showSupportSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  String category = 'support',
  String hint = 'How can we help?',
  String? prefix,
}) async {
  final String? reference = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _SupportForm(
      title: title,
      subtitle: subtitle,
      category: category,
      hint: hint,
      prefix: prefix,
    ),
  );
  if (reference != null && context.mounted) {
    AppFeedback.toast(
      context,
      'Sent — reference $reference. We’ll reply by email.',
    );
  }
}

class _SupportForm extends ConsumerStatefulWidget {
  const _SupportForm({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.hint,
    this.prefix,
  });

  final String title;
  final String subtitle;
  final String category;
  final String hint;

  /// Added in front of the message, e.g. "Clinical supervision request".
  final String? prefix;

  @override
  ConsumerState<_SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends ConsumerState<_SupportForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    String? reference;
    final String text = widget.prefix == null
        ? _message.text.trim()
        : '${widget.prefix}\n\n${_message.text.trim()}';
    final bool ok = await AppFeedback.guard(context, () async {
      reference = await ref
          .read(repositoryProvider)
          .contactSupport(text, category: widget.category);
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(reference);
    } else {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg,
        0,
        AppSizes.lg,
        AppSizes.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.title, style: AppTypography.headingSmall),
            const SizedBox(height: AppSizes.xs),
            Text(widget.subtitle, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSizes.lg),
            MistyTextField(
              label: 'Your message',
              controller: _message,
              hint: widget.hint,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              validator: (String? v) => (v ?? '').trim().length < 5
                  ? 'Please tell us a little more.'
                  : null,
            ),
            const SizedBox(height: AppSizes.lg),
            MistyPrimaryButton(
              label: 'Send',
              isLoading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
