import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _id = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(authProvider.notifier).login(_id.text, _password.text),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.go(AppRoutes.home);
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleBusy = true);
    bool signedIn = false;
    final bool ok = await AppFeedback.guard(context, () async {
      signedIn = await ref.read(authProvider.notifier).loginWithGoogle();
    });
    if (!mounted) return;
    setState(() => _googleBusy = false);
    if (ok && signedIn) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      illustration: AppAssets.cloudReady,
      children: <Widget>[
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MistyTextField(
                  label: AppStrings.emailOrMobile,
                  controller: _id,
                  hint: AppStrings.emailOrMobileHint,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: Validators.emailOrPhone,
                ),
                const SizedBox(height: AppSizes.lg),
                MistyTextField(
                  label: AppStrings.password,
                  controller: _password,
                  hint: AppStrings.passwordHint,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  validator: Validators.password,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: MistyLinkButton(
            label: AppStrings.forgotPassword,
            onPressed: () => context.push(AppRoutes.forgotPassword),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        MistyPrimaryButton(
          label: AppStrings.login,
          isLoading: _busy,
          onPressed: _googleBusy ? null : _login,
        ),
        const SizedBox(height: AppSizes.md),
        MistySecondaryButton(
          label: _googleBusy ? 'Signing in…' : 'Continue with Google',
          leading: const Icon(Icons.g_mobiledata_rounded, size: 28),
          onPressed: _busy || _googleBusy ? null : _google,
        ),
        const SizedBox(height: AppSizes.xxl),
        Center(
          child: Text(
            AppStrings.notPartnerYet,
            style: AppTypography.bodyMedium,
          ),
        ),
        Center(
          child: MistyLinkButton(
            label: AppStrings.applyToJoinShort,
            arrow: true,
            onPressed: () => context.push(AppRoutes.apply),
          ),
        ),
      ],
    );
  }
}
