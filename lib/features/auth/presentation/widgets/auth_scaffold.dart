import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_app_bar.dart';

/// Shared frame for every auth screen: pale sky ground, a round back button,
/// a small cloud mascot, a serif title and a scrolling form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.illustration = AppAssets.cloudCalm,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String illustration;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const MistyAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.sm,
                    AppSizes.screenPadding,
                    AppSizes.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Image.asset(
                          illustration,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.xxl),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.sm,
                    AppSizes.screenPadding,
                    AppSizes.lg,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
