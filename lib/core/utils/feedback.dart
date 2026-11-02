import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../data/api/api_exception.dart';

/// Snack bars and confirmation dialogs, styled once.
abstract final class AppFeedback {
  static void toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs [action]; if it fails, shows the reason (the backend's own
  /// message for an `ApiException`) and returns false.
  static Future<bool> guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message);
    } catch (_) {
      if (context.mounted) toast(context, ApiException.network.message);
    }
    return false;
  }

  /// A calm two-button confirmation. Resolves to true on confirm.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          0,
          AppSizes.lg,
          AppSizes.lg,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: AppTypography.body(
                14.5,
                weight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: AppTypography.body(
                14.5,
                weight: FontWeight.w700,
                color: destructive ? AppColors.coral : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
