import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('check image sizes', () {
    final files = [
      'assets/images/onepiece.png',
      'assets/images/light.png',
    ];

    for (var path in files) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync().take(24).toList();
        final width = (bytes[16] << 24) +
            (bytes[17] << 16) +
            (bytes[18] << 8) +
            bytes[19];
        final height = (bytes[20] << 24) +
            (bytes[21] << 16) +
            (bytes[22] << 8) +
            bytes[23];
        debugPrint('SIZE_CHECK: ${path.split('/').last}: ${width}x$height');
      } else {
        debugPrint('SIZE_CHECK: $path not found');
      }
    }
  });
}
