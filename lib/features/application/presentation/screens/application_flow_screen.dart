import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../application_form.dart';
import '../widgets/application_steps.dart';

/// The seven-step "Apply to Join as a Psychologist" flow.
class ApplicationFlowScreen extends ConsumerStatefulWidget {
  const ApplicationFlowScreen({super.key});

  @override
  ConsumerState<ApplicationFlowScreen> createState() =>
      _ApplicationFlowScreenState();
}

class _ApplicationFlowScreenState extends ConsumerState<ApplicationFlowScreen> {
  static const List<(String, String)> _steps = <(String, String)>[
    ('Personal details', 'Let’s start with the basics.'),
    ('Professional details', 'Your qualifications and experience.'),
    ('Your practice', 'Who you help and how you like to work.'),
    ('Registration', 'Your licence to practise.'),
    ('Documents', 'Upload proof so we can verify you.'),
    ('Bank details', 'Where your earnings will be paid.'),
    ('Review & submit', 'Check everything before you send it.'),
  ];

  final ApplicationForm _form = ApplicationForm();
  final List<GlobalKey<FormState>> _keys = List<GlobalKey<FormState>>.generate(
    _steps.length,
    (_) => GlobalKey<FormState>(),
  );
  final ScrollController _scroll = ScrollController();
  int _step = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _form.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    final FormState? state = _keys[_step].currentState;
    if (state != null && !state.validate()) return;

    if (_step == 2 && _form.specializations.isEmpty) {
      AppFeedback.toast(context, 'Choose at least one specialisation');
      return;
    }
    if (_step == 4 && !_form.hasPhoto) {
      AppFeedback.toast(context, 'Please upload your professional photo');
      return;
    }
    if (_step == 4 && !_form.documentsComplete) {
      AppFeedback.toast(context, 'Please upload all required documents');
      return;
    }
    if (_step < _steps.length - 1) {
      _goTo(_step + 1);
      return;
    }
    if (!_form.consent) {
      AppFeedback.toast(context, 'Please confirm the declaration to submit');
      return;
    }
    setState(() => _submitting = true);
    String reference = '';
    final bool ok = await AppFeedback.guard(context, () async {
      reference = await ref
          .read(repositoryProvider)
          .submitApplication(_form.toPayload());
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) return;
    context.go(
      Uri(
        path: AppRoutes.applicationSubmitted,
        queryParameters: <String, String>{'ref': reference},
      ).toString(),
    );
  }

  Widget _body() {
    void changed() => setState(() {});
    return switch (_step) {
      0 => PersonalStep(form: _form, onChanged: changed),
      1 => ProfessionalStep(form: _form, onChanged: changed),
      2 => PracticeStep(form: _form, onChanged: changed),
      3 => RegistrationStep(form: _form, onChanged: changed),
      4 => DocumentsStep(form: _form, onChanged: changed),
      5 => BankStep(form: _form),
      _ => ReviewStep(form: _form, onEdit: _goTo, onChanged: changed),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle) = _steps[_step];
    final bool last = _step == _steps.length - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _goTo(_step - 1);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              MistyAppBar(
                title: 'Apply to Join',
                onBack: () => _step == 0 ? context.pop() : _goTo(_step - 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.sm,
                  AppSizes.screenPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'STEP ${_step + 1} OF ${_steps.length}',
                      style: AppTypography.body(
                        11.5,
                        weight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    ClipRRect(
                      borderRadius: AppSizes.brPill,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: (_step + 1) / _steps.length),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (_, double v, _) =>
                            LinearProgressIndicator(value: v, minHeight: 6),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(title, style: AppTypography.displayMedium),
                    const SizedBox(height: AppSizes.xs),
                    Text(subtitle, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.xl,
                    AppSizes.screenPadding,
                    AppSizes.xxl,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Form(
                      key: _keys[_step],
                      child: KeyedSubtree(
                        key: ValueKey<int>(_step),
                        child: _body(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.sm,
                  AppSizes.screenPadding,
                  AppSizes.lg,
                ),
                child: MistyPrimaryButton(
                  label: last ? 'Submit Application' : 'Continue',
                  trailingIcon: last ? null : Icons.arrow_forward_rounded,
                  isLoading: _submitting,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
