import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/push/push_service.dart';
import '../../../../state/providers.dart';

/// Client calls reach a closed phone only through push notifications. This
/// checks — on open and every time the app comes back to the foreground —
/// that notifications are allowed and this phone is registered, re-registers
/// it, and if something is off shows a clear card with a "Turn on" button.
class PushHealthBanner extends ConsumerStatefulWidget {
  const PushHealthBanner({super.key});

  @override
  ConsumerState<PushHealthBanner> createState() => _PushHealthBannerState();
}

class _PushHealthBannerState extends ConsumerState<PushHealthBanner>
    with WidgetsBindingObserver {
  bool _ok = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final bool allowed = await PushService.instance.notificationsAllowed();
      final bool registered = allowed &&
          await ref.read(authProvider.notifier).retryPushRegistration();
      if (mounted) setState(() => _ok = allowed && registered);
    } finally {
      _checking = false;
    }
  }

  Future<void> _turnOn() async {
    final PermissionStatus status = await Permission.notification.request();
    if (status.isPermanentlyDenied || status.isDenied) {
      await openAppSettings();
      return; // _check() runs again when they come back.
    }
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    if (_ok || !PushService.isAvailable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md + 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E6),
          borderRadius: AppSizes.brCard,
          border: Border.all(color: const Color(0xFFF5C9A6)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFFB4561A),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Turn on notifications',
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Without them you won’t hear client calls when the app is '
                    'closed. ${PushService.instance.lastProblem ?? ''}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            FilledButton(
              onPressed: _turnOn,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Turn on'),
            ),
          ],
        ),
      ),
    );
  }
}
