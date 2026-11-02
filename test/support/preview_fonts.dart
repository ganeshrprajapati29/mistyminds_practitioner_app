import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the real brand faces and Material icons with the test renderer,
/// so preview shots carry real typography instead of placeholder boxes.
Future<void> loadPreviewFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await _load('PlayfairDisplay', <String>[
    'assets/fonts/PlayfairDisplay-Variable.ttf',
  ]);
  await _load('Inter', <String>['assets/fonts/Inter-Variable.ttf']);
  await _load('DancingScript', <String>[
    'assets/fonts/DancingScript-Variable.ttf',
  ]);

  final String? root = _flutterRoot();
  if (root != null) {
    await _load('MaterialIcons', <String>[
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    ]);
  }
}

Future<void> _load(String family, List<String> candidates) async {
  for (final String path in candidates) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final FontLoader loader = FontLoader(family)
      ..addFont(
        Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    await loader.load();
    return;
  }
}

String? _flutterRoot() {
  final String? fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && Directory(fromEnv).existsSync()) return fromEnv;
  Directory dir = File(Platform.resolvedExecutable).parent;
  for (int i = 0; i < 6; i++) {
    if (Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    ).existsSync()) {
      return dir.path;
    }
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}
