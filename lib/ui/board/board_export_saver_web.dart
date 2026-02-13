import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'dart:html' as html;

Future<void> savePng({
  required ScaffoldMessengerState messenger,
  required Uint8List bytes,
  required String defaultName,
}) async {
  final blob = html.Blob(<dynamic>[bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement(href: url)
      ..download = defaultName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    messenger.showSnackBar(const SnackBar(content: Text('已开始下载')));
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
