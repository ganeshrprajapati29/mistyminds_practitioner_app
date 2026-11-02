import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The one text field used across auth, application and profile forms: a
/// label above a rounded white field. Owns its own show/hide password toggle.
class MistyTextField extends StatefulWidget {
  const MistyTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  State<MistyTextField> createState() => _MistyTextFieldState();
}

class _MistyTextFieldState extends State<MistyTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: AppTypography.label),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          cursorColor: AppColors.primary,
          style: AppTypography.body(15.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: AppSizes.iconMd),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppSizes.iconMd,
                    ),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}

/// Simple validators for the app's forms.
abstract final class Validators {
  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? emailOrPhone(String? v) {
    final String s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email or mobile number';
    final bool email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    final bool phone = RegExp(r'^\+?\d{10,13}$').hasMatch(s);
    return email || phone ? null : 'Enter a valid email or 10-digit mobile';
  }

  static String? password(String? v) {
    if ((v ?? '').isEmpty) return 'Enter your password';
    if (v!.length < 6) return 'Use at least 6 characters';
    return null;
  }
}
