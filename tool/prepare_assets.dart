// Turns the raw brand drops in `assets/` into app-ready artwork.
//
//   assets/images/  in-app artwork (cut-outs, optimised welcome scene, logo)
//   assets/brand/   launcher-icon layers and native-splash images
//
// The raw files cannot all be drawn as-is:
//
//   * `cloud1.jpeg` / `cloud2.jpeg` are mascots rendered on solid black. They
//     are keyed out from the border inwards and un-premultiplied from black,
//     so their soft rims stay soft on a lavender screen instead of wearing a
//     dark halo. The dark eyes survive because they are enclosed by the cloud.
//   * `anonymous_client.png` / `empty_waiting_request.png` already carry real
//     alpha; they are only trimmed and downscaled.
//   * `psychologist_welcome_bg.png` is an opaque scene — shipped as a JPEG.
//   * `app_logo.jpeg` is the "MP" monogram tile used for the launcher icon.
//
// Run with:  dart run tool/prepare_assets.dart
// Then:      dart run flutter_launcher_icons
//            dart run flutter_native_splash:create
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const String _src = 'assets';
const String _images = 'assets/images';
const String _brand = 'assets/brand';

void main() {
  Directory(_images).createSync(recursive: true);
  Directory(_brand).createSync(recursive: true);

  // ---- In-app artwork -------------------------------------------------------
  _writeJpg(
    '$_images/welcome_bg.jpg',
    _fit(_load('psychologist_welcome_bg.png'), 1800),
  );
  _writePng(
    '$_images/cloud_ready.png',
    _fit(_trim(_keyOutBlack(_load('cloud2.jpeg'))), 720),
  );
  _writePng(
    '$_images/cloud_calm.png',
    _fit(_trim(_keyOutBlack(_load('cloud1.jpeg'))), 720),
  );
  _writeJpg(
    '$_images/cloud_listening.jpg',
    _fit(_load('cloud_headphone.jpeg'), 900),
  );
  _writePng(
    '$_images/anonymous_client.png',
    _fit(_trim(_load('anonymous_client.png')), 560),
  );
  _writePng(
    '$_images/waiting_request.png',
    _fit(_trim(_load('empty_waiting_request.png')), 720),
  );
  _writePng(
    '$_images/logo_wordmark.png',
    _trim(_load('logo-removebg-preview.png')),
  );

  // ---- Launcher icon ------------------------------------------------------
  final img.Image tile = _squareCrop(_load('app_logo.jpeg'), inset: 6);

  // iOS / legacy / web: the full monogram tile.
  final img.Image icon = _resize(tile, 1024);
  _writePng('$_brand/app_icon.png', icon);

  // Android adaptive background: the pastel wash with the glyph painted out,
  // so the launcher mask can crop it to any shape.
  _writePng('$_brand/app_icon_background.png', _washWithoutGlyph(tile, 1024));

  // Android adaptive foreground: just the navy "MP", inset in the safe zone.
  final img.Image glyph = _trim(_glyphOnly(tile));
  _writePng('$_brand/app_icon_foreground.png', _centerOn(glyph, 1024, 640));

  // ---- Splash ---------------------------------------------------------------
  // The splash shows the wordmark alone — one logo, never the icon tile too.
  // Both images put it 700 px wide at 4x (175 dp), the size the Flutter splash
  // draws it at, so the hand-off from native to Flutter does not jump.
  final img.Image wordmark = _trim(_load('logo-removebg-preview.png'));
  _writePng('$_brand/splash_logo.png', _centerOn(wordmark, 720, 700));

  // Android 12+ masks the splash icon to a circle two thirds of the canvas
  // wide; a 700 px wordmark fits inside it corner to corner.
  _writePng(
    '$_brand/splash_logo_android12.png',
    _centerOn(wordmark, 1152, 700),
  );

  _writeNavIcons();

  stdout.writeln('Done.');
}

// ---------------------------------------------------------------------------
// Bottom-navigation icons
// ---------------------------------------------------------------------------

const String _navDir = 'assets/icons/nav';

/// Glyph colours in the supplied icons (gradient stops and accents).
const List<String> _glyphInks = <String>[
  '#9B72F2',
  '#9C73F4',
  '#5146E5',
  '#6553E8',
  '#7561EB',
  '#A995F4',
  '#B7A6F5',
  '#B8A8F4',
  '#72D9B5',
  '#8EE9C5',
  '#45C69B',
];

/// Writes a ready-to-draw active and inactive SVG for each tab.
///
/// The supplied icons sit on their own lavender tile, which does not belong
/// in a tab bar. Doing the tile removal and recolouring here, once, means the
/// app draws plain asset files instead of rewriting SVG source at runtime.
void _writeNavIcons() {
  Directory(_navDir).createSync(recursive: true);
  final RegExp tile = RegExp(
    r'<rect x="8" y="8" width="80" height="80" rx="24"[^>]*/>',
  );
  for (final String name in <String>[
    'home',
    'calendar',
    'clients',
    'wallet',
    'profile',
  ]) {
    final String source = File('$_src/icon_$name.svg').readAsStringSync();
    // Drop the tile and pad the viewBox so no glyph touches its edge (the
    // three-person clients glyph spans nearly the full width).
    String bare = source
        .replaceFirst(tile, '')
        .replaceFirst('viewBox="0 0 96 96"', 'viewBox="8 8 80 80"')
        .replaceAll(RegExp('#F4F1FF|#F3F0FF', caseSensitive: false), '#FFFFFF');
    File('$_navDir/${name}_active.svg').writeAsStringSync(bare);

    for (final String ink in _glyphInks) {
      bare = bare.replaceAll(RegExp(ink, caseSensitive: false), '#9A9EB8');
    }
    File('$_navDir/${name}_inactive.svg').writeAsStringSync(bare);
    stdout.writeln('  $_navDir/${name}_{active,inactive}.svg');
  }
}

// ---------------------------------------------------------------------------
// IO
// ---------------------------------------------------------------------------

img.Image _load(String name) {
  final img.Image? image = img.decodeImage(
    File('$_src/$name').readAsBytesSync(),
  );
  if (image == null) throw StateError('Could not decode $name');
  return image.convert(numChannels: 4);
}

void _writePng(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image, level: 9));
  _report(path, image);
}

void _writeJpg(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 88));
  _report(path, image);
}

void _report(String path, img.Image image) {
  final int kb = File(path).lengthSync() ~/ 1024;
  stdout.writeln(
    '  ${path.padRight(44)} ${image.width}x${image.height} ${kb}KB',
  );
}

// ---------------------------------------------------------------------------
// Keying
// ---------------------------------------------------------------------------

int _maxChannel(img.Pixel p) =>
    math.max(p.r.toInt(), math.max(p.g.toInt(), p.b.toInt()));

/// Removes a solid black backdrop by flood-filling from every border pixel.
///
/// Pixels dimmer than [solid] are treated as black mixed with artwork: their
/// alpha is how bright they are, and their colour is divided back out of the
/// black so the rim keeps its true tint. The fill stops at artwork, so dark
/// details *inside* the mascot (eyes, mouth) are never touched.
img.Image _keyOutBlack(img.Image src, {int solid = 170}) {
  final img.Image out = src.clone();
  final int w = out.width, h = out.height;
  final List<bool> seen = List<bool>.filled(w * h, false);
  final Queue<int> queue = Queue<int>();

  void visit(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final int i = y * w + x;
    if (seen[i]) return;
    seen[i] = true;
    if (_maxChannel(out.getPixel(x, y)) < solid) queue.add(i);
  }

  for (int x = 0; x < w; x++) {
    visit(x, 0);
    visit(x, h - 1);
  }
  for (int y = 0; y < h; y++) {
    visit(0, y);
    visit(w - 1, y);
  }

  while (queue.isNotEmpty) {
    final int i = queue.removeFirst();
    final int x = i % w, y = i ~/ w;
    final img.Pixel p = out.getPixel(x, y);
    final int m = _maxChannel(p);
    if (m < 14) {
      p
        ..r = 0
        ..g = 0
        ..b = 0
        ..a = 0;
    } else {
      final double a = (m / solid).clamp(0.0, 1.0);
      p
        ..r = (p.r / a).clamp(0, 255).round()
        ..g = (p.g / a).clamp(0, 255).round()
        ..b = (p.b / a).clamp(0, 255).round()
        ..a = (a * 255).round();
    }
    visit(x - 1, y);
    visit(x + 1, y);
    visit(x, y - 1);
    visit(x, y + 1);
  }
  return out;
}

double _luma(img.Pixel p) => 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

/// Keeps only the dark calligraphic glyph, recoloured to one clean navy.
img.Image _glyphOnly(img.Image tile) {
  final img.Image out = tile.clone();
  const double ink = 50, paper = 130;
  for (final img.Pixel p in out) {
    // The JPEG border carries a few dark specks; the glyph never reaches it.
    final int margin = tile.width ~/ 40;
    if (p.x < margin ||
        p.y < margin ||
        p.x > tile.width - margin ||
        p.y > tile.height - margin) {
      p.a = 0;
      continue;
    }
    final double l = _luma(p);
    final double a = ((paper - l) / (paper - ink)).clamp(0.0, 1.0);
    p
      ..r = 17
      ..g = 24
      ..b = 58
      ..a = (a * 255).round();
  }
  return out;
}

/// Rebuilds the pastel gradient under the glyph.
///
/// The tile is sampled on a coarse grid that ignores glyph pixels, then scaled
/// back up with cubic interpolation — the wash is smooth enough that nothing
/// of the glyph survives.
img.Image _washWithoutGlyph(img.Image tile, int size) {
  const int grid = 32;
  final img.Image small = img.Image(width: grid, height: grid, numChannels: 4);
  final double cw = tile.width / grid, ch = tile.height / grid;
  List<double>? last;
  for (int gy = 0; gy < grid; gy++) {
    for (int gx = 0; gx < grid; gx++) {
      double r = 0, g = 0, b = 0;
      int n = 0;
      for (int y = (gy * ch).floor(); y < ((gy + 1) * ch).floor(); y++) {
        for (int x = (gx * cw).floor(); x < ((gx + 1) * cw).floor(); x++) {
          final img.Pixel p = tile.getPixel(x, y);
          if (_luma(p) < 120) continue;
          r += p.r;
          g += p.g;
          b += p.b;
          n++;
        }
      }
      final List<double> c = n == 0
          ? (last ?? <double>[230, 220, 250])
          : <double>[r / n, g / n, b / n];
      last = c;
      small.setPixelRgba(gx, gy, c[0].round(), c[1].round(), c[2].round(), 255);
    }
  }
  return img.gaussianBlur(
    img.copyResize(
      small,
      width: size,
      height: size,
      interpolation: img.Interpolation.linear,
    ),
    radius: 40,
  );
}

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

img.Image _trim(img.Image image, {int pad = 6}) {
  int top = image.height, left = image.width, right = -1, bottom = -1;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a <= 8) continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  if (right < 0) return image;
  left = math.max(0, left - pad);
  top = math.max(0, top - pad);
  right = math.min(image.width - 1, right + pad);
  bottom = math.min(image.height - 1, bottom + pad);
  return img.copyCrop(
    image,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}

img.Image _fit(img.Image image, int maxSide) {
  if (math.max(image.width, image.height) <= maxSide) return image;
  return image.width >= image.height
      ? img.copyResize(
          image,
          width: maxSide,
          interpolation: img.Interpolation.cubic,
        )
      : img.copyResize(
          image,
          height: maxSide,
          interpolation: img.Interpolation.cubic,
        );
}

img.Image _resize(img.Image image, int side) => img.copyResize(
  image,
  width: side,
  height: side,
  interpolation: img.Interpolation.cubic,
);

img.Image _squareCrop(img.Image image, {int inset = 0}) {
  final int side = math.min(image.width, image.height) - inset * 2;
  return img.copyCrop(
    image,
    x: (image.width - side) ~/ 2,
    y: (image.height - side) ~/ 2,
    width: side,
    height: side,
  );
}

/// Scales [art] to fit a [box]-sized square and centres it on a transparent
/// [canvas]-sized square.
img.Image _centerOn(img.Image art, int canvas, int box) {
  final double scale = box / math.max(art.width, art.height);
  final img.Image scaled = img.copyResize(
    art,
    width: (art.width * scale).round(),
    height: (art.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
  final img.Image out = img.Image(
    width: canvas,
    height: canvas,
    numChannels: 4,
  );
  img.fill(out, color: img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(
    out,
    scaled,
    dstX: (canvas - scaled.width) ~/ 2,
    dstY: (canvas - scaled.height) ~/ 2,
  );
  return out;
}
