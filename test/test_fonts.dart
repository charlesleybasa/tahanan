import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled fonts so text measures as on device (the default test font is far wider).
Future<void> loadAppFonts() async {
  for (final family in ['Outfit', 'Manrope', 'JetBrainsMono']) {
    final loader = FontLoader(family);
    for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
      if (f.path.split('/').last.startsWith('$family-')) {
        loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await loader.load();
  }
}
