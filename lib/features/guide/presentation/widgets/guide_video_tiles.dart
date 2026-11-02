import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_menu_tile.dart';
import '../../../../data/models/guide_video.dart';
import '../../../../state/providers.dart';
import '../screens/guide_video_player.dart';

/// Opens [video] in the full-screen player, above the tab bar.
void openGuideVideo(BuildContext context, GuideVideo video) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) => GuideVideoPlayer(
        video: video,
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

/// A menu row that plays [video] — for the lists on Profile and Help.
class GuideVideoTile extends StatelessWidget {
  const GuideVideoTile({super.key, required this.video});

  final GuideVideo video;

  @override
  Widget build(BuildContext context) {
    return MistyMenuTile(
      title: video.title,
      subtitle: video.description.isEmpty ? 'Watch video' : video.description,
      icon: Icons.play_circle_outline_rounded,
      onTap: () => openGuideVideo(context, video),
    );
  }
}

/// The videos the admin console placed on Home, one card each. Takes no space
/// when there are none.
class HomeGuideVideos extends ConsumerWidget {
  const HomeGuideVideos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<GuideVideo> videos = ref.watch(
      videosForPlacementProvider(VideoPlacement.home),
    );
    return Column(
      children: <Widget>[
        for (final GuideVideo video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.lg),
            child: _GuideVideoCard(video: video),
          ),
      ],
    );
  }
}

class _GuideVideoCard extends StatelessWidget {
  const _GuideVideoCard({required this.video});

  final GuideVideo video;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lavender,
      borderRadius: AppSizes.brCard,
      child: InkWell(
        onTap: () => openGuideVideo(context, video),
        borderRadius: AppSizes.brCard,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      video.title,
                      style: AppTypography.body(
                        16,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.description.isEmpty
                          ? 'Tap to watch'
                          : video.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (video.watched) ...<Widget>[
                const SizedBox(width: AppSizes.sm),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.mint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
