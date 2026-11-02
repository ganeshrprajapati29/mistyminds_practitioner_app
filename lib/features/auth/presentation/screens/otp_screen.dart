import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/auth_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.destination});

  final String destination;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _length = 6;
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _secondsLeft = 30;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _code.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_secondsLeft == 0) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref
          .read(repositoryProvider)
          .verifyOtp(widget.destination, _code.text),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      _code.clear();
      return;
    }
    context.pushReplacement(
      Uri(
        path: AppRoutes.resetPassword,
        queryParameters: <String, String>{'to': widget.destination},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String target = widget.destination.isEmpty
        ? 'your registered email'
        : widget.destination;

    return AuthScaffold(
      title: 'Verify it’s you',
      subtitle: 'Enter the 6-digit code we sent to\n$target',
      children: <Widget>[
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Stack(
            children: <Widget>[
              // A single hidden field drives the six boxes — paste and
              // autofill work for free.
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 56,
                  child: TextField(
                    controller: _code,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: _length,
                    autofillHints: const <String>[AutofillHints.oneTimeCode],
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < _length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _box(i),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        Center(
          child: _secondsLeft > 0
              ? Text(
                  'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: AppTypography.bodySmall,
                )
              : MistyLinkButton(
                  label: 'Resend code',
                  onPressed: () async {
                    final bool ok = await AppFeedback.guard(
                      context,
                      () => ref
                          .read(repositoryProvider)
                          .requestPasswordReset(widget.destination),
                    );
                    if (!ok || !context.mounted) return;
                    _startTimer();
                    AppFeedback.toast(context, 'A new code is on its way');
                  },
                ),
        ),
        const SizedBox(height: AppSizes.xl),
        MistyPrimaryButton(
          label: 'Verify',
          isLoading: _busy,
          onPressed: _code.text.length == _length ? _verify : null,
        ),
      ],
    );
  }

  Widget _box(int i) {
    final String text = _code.text;
    final bool filled = i < text.length;
    final bool active =
        _focus.hasFocus && i == text.length.clamp(0, _length - 1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.brMd,
        border: Border.all(
          color: active
              ? AppColors.primary
              : (filled ? AppColors.primaryMuted : AppColors.border),
          width: active ? 1.6 : 1.2,
        ),
        boxShadow: active ? AppColors.softShadow : null,
      ),
      child: Text(
        filled ? text[i] : '',
        style: AppTypography.display(24, weight: FontWeight.w600),
      ),
    );
  }
}
