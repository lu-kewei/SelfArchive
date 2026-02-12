import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class BoardExporter {
  static Future<void> exportBoard({
    required BuildContext context,
    required GlobalKey repaintBoundaryKey,
    double? pixelRatio,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final view = View.of(context);
    final defaultName =
        "self_archive_${DateTime.now().millisecondsSinceEpoch}.png";
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('导出失败：未找到画布视图')),
        );
        return;
      }

      final baseRatio = view.devicePixelRatio;
      final requestedRatio = pixelRatio ?? (baseRatio * 2.0);

      const maxPixels = 20 * 1000 * 1000;
      final logicalSize = boundary.size;
      final logicalPixels = logicalSize.width * logicalSize.height;
      var ratio = requestedRatio;
      if (logicalPixels > 0) {
        final estimatedPixels = logicalPixels * requestedRatio * requestedRatio;
        if (estimatedPixels > maxPixels) {
          ratio = math.sqrt(maxPixels / logicalPixels);
        }
      }
      ratio = ratio.clamp(1.0, requestedRatio).toDouble();

      final image = await boundary.toImage(pixelRatio: ratio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('导出失败：生成图片数据失败')),
        );
        return;
      }

      await _savePng(
        messenger: messenger,
        bytes: pngBytes,
        defaultName: defaultName,
      );
    } catch (e) {
      debugPrint("Export error: $e");
      messenger.showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  static Future<void> _savePng({
    required ScaffoldMessengerState messenger,
    required Uint8List bytes,
    required String defaultName,
  }) async {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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
}
