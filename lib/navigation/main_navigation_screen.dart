import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/feedback.dart';
import '../core/widgets/misty_bottom_navigation.dart';
import '../data/models/guide_video.dart';
import '../features/guide/presentation/screens/guide_video_player.dart';
import '../state/providers.dart';

/// Hosts the five tabs from the reference: Home, Calendar, Clients, Earnings
/// and Profile.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  static final List<MistyNavItem> _items = <MistyNavItem>[
    for (final (String label, String icon) in <(String, String)>[
      ('Home', 'home'),
      ('Calendar', 'calendar'),
      ('Clients', 'clients'),
      ('Earnings', 'wallet'),
      ('Profile', 'profile'),
    ])
      MistyNavItem(
        label: label,
        activeIcon: AppAssets.navActive(icon),
        inactiveIcon: AppAssets.navInactive(icon),
      ),
  ];

  DateTime? _lastBack;

  void _onTap(int index) => widget.shell.goBranch(
    index,
    // Tapping the current tab again returns it to its root.
    initialLocation: index == widget.shell.currentIndex,
  );

  void _handleBack() {
    if (widget.shell.currentIndex != 0) {
      widget.shell.goBranch(0);
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    AppFeedback.toast(context, 'Press back again to exit');
  }

  @override
  Widget build(BuildContext context) {
    // A video the admin console wants seen after signing in covers the whole
    // app until it has been watched (see GuideVideoPlayer).
    final GuideVideo? loginVideo = ref.watch(pendingLoginVideoProvider);
    // Until the first answer arrives, so Home doesn't flash before the video.
    final bool checkingVideos = ref.watch(
      guideVideosProvider.select(
        (AsyncValue<List<GuideVideo>> v) => v.isLoading && !v.hasValue,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && loginVideo == null) _handleBack();
      },
      child: Stack(
        children: <Widget>[
          Scaffold(
            backgroundColor: AppColors.background,
            body: widget.shell,
            bottomNavigationBar: MistyBottomNavigation(
              items: _items,
              currentIndex: widget.shell.currentIndex,
              onTap: _onTap,
            ),
          ),
          if (checkingVideos)
            const Positioned.fill(
              child: ColoredBox(color: AppColors.background),
            ),
          if (loginVideo != null)
            Positioned.fill(
              child: GuideVideoPlayer(
                key: ValueKey<String>(loginVideo.id),
                video: loginVideo,
              ),
            ),
        ],
      ),
    );
  }
}
