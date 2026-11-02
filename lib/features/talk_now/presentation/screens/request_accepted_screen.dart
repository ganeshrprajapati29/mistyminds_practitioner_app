import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/talk_request.dart';
import '../../../../navigation/app_routes.dart';
import '../../../consultation/presentation/consultation_args.dart';

/// A short, calm hand-off between accepting and the consultation opening.
class RequestAcceptedScreen extends StatefulWidget {
  const RequestAcceptedScreen({super.key, required this.accepted});

  final AcceptedTalk accepted;

  @override
  State<RequestAcceptedScreen> createState() => _RequestAcceptedScreenState();
}

class _RequestAcceptedScreenState extends State<RequestAcceptedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final String route = switch (widget.accepted.request.mode) {
        ConsultMode.chat => AppRoutes.chat,
        ConsultMode.audio => AppRoutes.audio,
        ConsultMode.video => AppRoutes.video,
      };
      context.pushReplacement(
        route,
        extra: ConsultationArgs.fromAccepted(widget.accepted),
      );
    });
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: Center(
          child: Padding(
            padding: AppSizes.pageInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _float,
                  builder: (BuildContext context, Widget? child) =>
                      Transform.translate(
                        offset: Offset(0, -8 * _float.value),
                        child: child,
                      ),
                  child: Image.asset(AppAssets.cloudReady, height: 140),
                ),
                const SizedBox(height: AppSizes.xxl),
                Text('Request accepted', style: AppTypography.displayMedium),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Connecting you over ${widget.accepted.request.mode.label.toLowerCase()}…\n'
                  'Take a breath. You’ve got this.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSizes.xxl),
                const SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: AppSizes.brPill,
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
