import 'package:flutter/material.dart';

/// The misty splash backdrop, drawn the same way — and in the same colours —
/// as the MistyMinds client app's splash (its `CloudBlob`, `CloudBackdrop` and
/// `AnimatedCloudBackdrop`), so both apps open on an identical screen.
abstract final class SplashPalette {
  static const Color primaryMuted = Color(0xFFCDBDFF);
  static const Color softLilac = Color(0xFFF2ECFF);
  static const Color softPink = Color(0xFFFFEEF5);
  static const Color softLavender = Color(0xFFEDE6FF);
  static const Color mintGreen = Color(0xFFE8F8F0);
  static const Color softSky = Color(0xFFEDF5FF);
}

/// A wide, soft ellipse — drifting mist rather than a bubble.
class CloudBlob extends StatelessWidget {
  const CloudBlob({
    super.key,
    required this.width,
    required this.height,
    this.color = SplashPalette.softLilac,
    this.opacity = 0.7,
  });

  final double width;
  final double height;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.all(
              Radius.elliptical(width / 2, height / 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft abstract cloud shapes drawn in Flutter rather than shipped as art.
class CloudBackdrop extends StatelessWidget {
  const CloudBackdrop({
    super.key,
    this.height = 220,
    this.tint = SplashPalette.primaryMuted,
    this.accent = SplashPalette.softPink,
    this.opacity = 1,
  });

  final double height;
  final Color tint;
  final Color accent;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _CloudPainter(tint: tint, accent: accent),
          ),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter({required this.tint, required this.accent});

  final Color tint;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint soft = Paint()..color = tint.withValues(alpha: 0.45);
    final Paint softer = Paint()..color = tint.withValues(alpha: 0.28);
    final Paint blush = Paint()..color = accent.withValues(alpha: 0.32);

    // Three overlapping blobs read as mist without looking like clip-art.
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.22),
      size.height * 0.34,
      softer,
    );
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.08),
      size.height * 0.26,
      soft,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.30),
      size.height * 0.30,
      blush,
    );
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.02),
      size.height * 0.22,
      softer,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.accent != accent;
}

/// Slowly drifting pastel clouds.
class AnimatedCloudBackdrop extends StatefulWidget {
  const AnimatedCloudBackdrop({
    super.key,
    this.height = 240,
    this.opacity = 0.7,
    this.tint = SplashPalette.primaryMuted,
    this.accent = SplashPalette.softPink,
  });

  final double height;
  final double opacity;
  final Color tint;
  final Color accent;

  @override
  State<AnimatedCloudBackdrop> createState() => _AnimatedCloudBackdropState();
}

class _AnimatedCloudBackdropState extends State<AnimatedCloudBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOut.transform(_controller.value);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Transform.translate(
                offset: Offset(-18 + 36 * t, 0),
                child: CloudBackdrop(
                  height: widget.height,
                  opacity: widget.opacity,
                  tint: widget.tint,
                  accent: widget.accent,
                ),
              ),
              Transform.translate(
                offset: Offset(24 - 48 * t, widget.height * 0.18),
                child: CloudBackdrop(
                  height: widget.height * 0.72,
                  opacity: widget.opacity * 0.58,
                  tint: SplashPalette.softLilac,
                  accent: SplashPalette.softSky,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
