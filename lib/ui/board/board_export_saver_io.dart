import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> savePng({
  required ScaffoldMessengerState messenger,
  required Uint8List bytes,
  required String defaultName,
}) async {
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  String? savedPath;
  var saveDialogSupported = true;
  try {
    savedPath = await FilePicker.platform.saveFile(
      dialogTitle: '选择保存位置',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: const ['png'],
    );
  } catch (_) {
    saveDialogSupported = false;
  }

  if (saveDialogSupported) {
    if (savedPath == null || savedPath.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('已取消保存')));
      return;
    }

    final file = File(savedPath);
    await file.writeAsBytes(bytes);
    messenger.showSnackBar(SnackBar(content: Text('已保存至: $savedPath')));
    return;
  }

  if (isDesktop) {
    messenger.showSnackBar(
      const SnackBar(content: Text('当前平台不支持选择保存路径')),
    );
    return;
  }

  final granted = await Permission.storage.request().isGranted ||
      await Permission.photos.request().isGranted;
  if (!granted) {
    messenger.showSnackBar(const SnackBar(content: Text('未授予权限，无法保存')));
    return;
  }

  final result = await ImageGallerySaver.saveImage(
    bytes,
    quality: 100,
    name: defaultName.replaceAll('.png', ''),
  );
  messenger.showSnackBar(SnackBar(content: Text('已保存到相册: $result')));
}
