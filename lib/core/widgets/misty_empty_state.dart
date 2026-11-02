import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// Shown when data couldn't be loaded (no connection, server down) — so an
/// unreachable server is never mistaken for an empty schedule.
class MistyErrorState extends StatelessWidget {
  const MistyErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return MistyEmptyState(
      title: 'We couldn’t load this',
      message:
          message ??
          'Please check your connection and try again. Nothing you saved is lost.',
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try again'),
      ),
    );
  }
}

/// A calm empty state: cloud artwork, a serif line and a supporting sentence.
class MistyEmptyState extends StatelessWidget {
  const MistyEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.image = AppAssets.cloudCalm,
    this.imageHeight = 120,
    this.action,
  });

  final String title;
  final String message;
  final String image;
  final double imageHeight;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xxl,
        vertical: AppSizes.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(image, height: imageHeight, fit: BoxFit.contain),
          const SizedBox(height: AppSizes.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSizes.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
