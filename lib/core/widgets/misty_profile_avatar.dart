import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A round portrait.
///
/// Shows, in order of preference: a network photo (once the backend supplies
/// one), the anonymous-client artwork, or soft pastel initials.
class MistyProfileAvatar extends StatelessWidget {
  const MistyProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    this.anonymous = false,
    this.ring = false,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final bool anonymous;

  /// A white ring with a soft halo — the dashboard's large portrait.
  final bool ring;

  String get _initials {
    final List<String> parts = name
        .replaceAll('Dr.', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final Widget fallback = anonymous
        ? Image.asset(AppAssets.anonymousClient, fit: BoxFit.cover)
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.pastelFor(name),
                  AppColors.lavenderStrong,
                ],
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppTypography.display(
                  size * 0.36,
                  weight: FontWeight.w700,
                  color: AppColors.pastelInkFor(name),
                ),
              ),
            ),
          );

    final Widget face = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );

    if (!ring) return face;
    return Container(
      padding: EdgeInsets.all(size * 0.04),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: AppColors.liftedShadow,
      ),
      child: face,
    );
  }
}
