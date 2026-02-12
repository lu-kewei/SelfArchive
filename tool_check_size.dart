import 'dart:io';

void main() {
  final files = [
    'assets/images/onepiece.png',
    'assets/images/light.png',
  ];

  final output = StringBuffer();

  for (var path in files) {
    final file = File(path);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync().take(24).toList();
      final width =
          (bytes[16] << 24) + (bytes[17] << 16) + (bytes[18] << 8) + bytes[19];
      final height =
          (bytes[20] << 24) + (bytes[21] << 16) + (bytes[22] << 8) + bytes[23];
      output.writeln('${path.split('/').last}: ${width}x$height');
    } else {
      output.writeln('$path not found');
    }
  }

  File('size_output.txt').writeAsStringSync(output.toString());
}
