import '../../core/config/app_config.dart';
import 'json.dart';

/// Where the Misty Minds team has chosen to show a video (set in the admin
/// console, per video).
enum VideoPlacement {
  /// Full screen, straight after signing in.
  afterLogin('after_login'),
  home('home'),
  profile('profile'),
  help('help');

  const VideoPlacement(this.wire);

  /// The name the backend uses.
  final String wire;
}

/// A video the Misty Minds team publishes to this app — the partner guide,
/// for one. Everything about it is decided in the admin console.
class GuideVideo {
  const GuideVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.placements,
    required this.mandatory,
    required this.watched,
  });

  /// `GET /practitioner/videos`
  factory GuideVideo.fromJson(Json j) => GuideVideo(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    url: AppConfig.resolveMedia(j['url'] as String?) ?? '',
    placements: <VideoPlacement>{
      for (final String name in stringList(j['placements']))
        for (final VideoPlacement p in VideoPlacement.values)
          if (p.wire == name) p,
    },
    mandatory: j['mandatory'] as bool? ?? false,
    watched: j['watched'] as bool? ?? false,
  );

  final String id;
  final String title;
  final String description;
  final String url;
  final Set<VideoPlacement> placements;

  /// After login: must be watched to the end — no skip, no seeking ahead.
  final bool mandatory;

  /// Whether this practitioner has already seen the current version.
  final bool watched;
}
