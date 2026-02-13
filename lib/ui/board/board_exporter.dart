import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'board_export_saver_io.dart'
    if (dart.library.html) 'board_export_saver_web.dart' as saver;

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
    await saver.savePng(
      messenger: messenger,
      bytes: bytes,
      defaultName: defaultName,
    );
  }
}
