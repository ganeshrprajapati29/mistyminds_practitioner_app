import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.identifier});

  /// The email or mobile the OTP was verified for.
  final String identifier;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref
          .read(repositoryProvider)
          .resetPassword(widget.identifier, _password.text),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Image.asset(AppAssets.cloudReady, height: 72),
        title: const Text('Password updated', textAlign: TextAlign.center),
        content: const Text(
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final GoRouter router = GoRouter.of(context);
    router.go(AppRoutes.welcome);
    router.push(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create a new password',
      subtitle: 'Choose something memorable — at least 6 characters.',
      children: <Widget>[
        Form(
          key: _form,
          child: Column(
            children: <Widget>[
              MistyTextField(
                label: 'New password',
                controller: _password,
                hint: 'New password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: true,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSizes.lg),
              MistyTextField(
                label: 'Confirm password',
                controller: _confirm,
                hint: 'Re-enter new password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (String? v) =>
                    v != _password.text ? 'Passwords don’t match' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Tip: a short phrase is easier to remember than random characters.',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSizes.xl),
        MistyPrimaryButton(
          label: 'Update Password',
          isLoading: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}
