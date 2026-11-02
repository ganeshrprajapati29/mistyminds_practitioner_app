import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Draws one of the supplied brand SVG icons.
///
/// Every supplied icon is a gradient glyph on its own soft lavender tile. The
/// icon can be drawn three ways:
///
///  * `MistySvgIcon(asset)` — exactly as supplied, tile included;
///  * `MistySvgIcon(asset, tile: false)` — the glyph alone, original colours
///    (selected navigation items, inline rows);
///  * `MistySvgIcon(asset, tile: false, color: c)` — the glyph recoloured to
///    one ink (unselected navigation, icons on a filled button).
///
/// Recolouring rewrites the SVG source instead of using a `srcIn` filter,
/// because the glyphs carry cut-outs painted in the tile colour (the house's
/// door, the bell's clapper) that a flat tint would erase.
class MistySvgIcon extends StatelessWidget {
  const MistySvgIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.tile = true,
    this.color,
    this.hollowColor = Colors.white,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final bool tile;
  final Color? color;

  /// Replaces the tile-coloured cut-outs when the tile is removed.
  final Color hollowColor;
  final String? semanticLabel;

  /// Loads every icon source once at start-up so recoloured icons draw on the
  /// first frame, with no async flash.
  static Future<void> preload(Iterable<String> assets) async {
    for (final String asset in assets) {
      _sources[asset] ??= await rootBundle.loadString(asset);
    }
  }

  static final Map<String, String> _sources = <String, String>{};
  static final Map<String, String> _variants = <String, String>{};

  static const List<String> _glyphInks = <String>[
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
  static const List<String> _tileInks = <String>['#F4F1FF', '#F3F0FF'];

  static final RegExp _tileRect = RegExp(
    r'<rect x="8" y="8" width="80" height="80" rx="24"[^>]*/>',
  );

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String? _variant() {
    final String? source = _sources[asset];
    if (source == null) return null;
    final String key = '$asset|$color|$hollowColor';
    return _variants.putIfAbsent(key, () {
      // Drop the tile and tighten the viewBox so the glyph fills the box.
      String svg = source
          .replaceFirst(_tileRect, '')
          .replaceFirst('viewBox="0 0 96 96"', 'viewBox="14 14 68 68"');
      final String hollow = _hex(hollowColor);
      for (final String ink in _tileInks) {
        svg = svg.replaceAll(RegExp(ink, caseSensitive: false), hollow);
      }
      if (color != null) {
        final String ink = _hex(color!);
        for (final String from in _glyphInks) {
          svg = svg.replaceAll(RegExp(from, caseSensitive: false), ink);
        }
      }
      return svg;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tile && color == null) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        semanticsLabel: semanticLabel,
      );
    }

    final String? svg = _variant();
    if (svg != null) {
      return SvgPicture.string(
        svg,
        width: size,
        height: size,
        semanticsLabel: semanticLabel,
      );
    }

    // Not preloaded (e.g. in a widget test): load, then draw.
    return FutureBuilder<void>(
      future: preload(<String>[asset]),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        final String? loaded = _variant();
        if (loaded == null) return SizedBox(width: size, height: size);
        return SvgPicture.string(loaded, width: size, height: size);
      },
    );
  }
}
