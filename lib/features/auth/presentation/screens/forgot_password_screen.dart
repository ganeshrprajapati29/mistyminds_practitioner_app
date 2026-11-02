import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _id = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(repositoryProvider).requestPasswordReset(_id.text.trim()),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    context.push(
      Uri(
        path: AppRoutes.otp,
        queryParameters: <String, String>{'to': _id.text.trim()},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password?',
      subtitle:
          'No worries. Enter the email or mobile number on your account and '
          'we’ll send you a 6-digit code.',
      children: <Widget>[
        Form(
          key: _form,
          child: MistyTextField(
            label: AppStrings.emailOrMobile,
            controller: _id,
            hint: AppStrings.emailOrMobileHint,
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.emailOrPhone,
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        MistyPrimaryButton(
          label: 'Send Code',
          isLoading: _busy,
          onPressed: _send,
        ),
        const SizedBox(height: AppSizes.xl),
        const MistyInfoNote(
          text:
              'For your clients’ safety, password resets are confirmed on '
              'both your email and registered mobile.',
        ),
      ],
    );
  }
}
