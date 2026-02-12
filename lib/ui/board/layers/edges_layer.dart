import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../utils/node_utils.dart';
import '../../../scene/models/node_entity.dart';
import '../../../scene/models/edge_entity.dart';
import '../../../core/theme/theme_pack.dart';

class EdgesLayer extends StatelessWidget {
  final List<NodeEntity> nodes;
  final List<EdgeEntity> edges;
  final ThemePack theme;

  const EdgesLayer({
    super.key,
    required this.nodes,
    required this.edges,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: EdgesPainter(
        nodes: nodes,
        edges: edges,
        theme: theme,
      ),
    );
  }
}

class EdgesPainter extends CustomPainter {
  final List<NodeEntity> nodes;
  final List<EdgeEntity> edges;
  final ThemePack theme;

  EdgesPainter({
    required this.nodes,
    required this.edges,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final basePaint = Paint()
      ..color = const Color(0xFF5C0A0A)
      ..strokeWidth = 4.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final corePaint = Paint()
      ..color = const Color(0xFF3D0404).withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final highlightPaint = Paint()
      ..color = const Color(0xFFFFC1C1).withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final twistPaint = Paint()
      ..color = const Color(0xFF2E0202).withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Cache node map for O(1) lookup
    final nodeMap = {for (var n in nodes) n.id: n};

    for (var edge in edges) {
      final from = nodeMap[edge.from.nodeId];
      final to = nodeMap[edge.to.nodeId];

      if (from != null && to != null) {
        final fromOffset = _getAnchorPosition(from, edge.from.anchorId);
        final toOffset = _getAnchorPosition(to, edge.to.anchorId);

        final path = Path();
        path.moveTo(fromOffset.dx, fromOffset.dy);

        // Quadratic bezier for slack
        // Calculate control point
        final midX = (fromOffset.dx + toOffset.dx) / 2;
        final midY = (fromOffset.dy + toOffset.dy) / 2;
        final dist = (fromOffset - toOffset).distance;

        // Slack calculation: natural drooping
        // Longer distance = more slack, but capped?
        // dist * 0.1 is reasonable for a "tight but heavy" rope.
        final slack = dist * 0.15;

        path.quadraticBezierTo(midX, midY + slack, toOffset.dx, toOffset.dy);

        canvas.drawPath(path, shadowPaint);

        canvas.drawPath(path, basePaint);

        final mainPaint = Paint()
          ..shader = ui.Gradient.linear(
            fromOffset,
            toOffset,
            const [
              Color(0xFF7A0C0C),
              Color(0xFFE02B2B),
              Color(0xFF8A1010),
            ],
            const [0.0, 0.55, 1.0],
          )
          ..strokeWidth = 3.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, mainPaint);
        canvas.drawPath(path, corePaint);

        final v = toOffset - fromOffset;
        final len = v.distance;
        if (len > 0.001) {
          final unit = Offset(v.dx / len, v.dy / len);
          final normal = Offset(-unit.dy, unit.dx);
          canvas.save();
          canvas.translate(normal.dx * 0.8, normal.dy * 0.8);
          canvas.drawPath(path, highlightPaint);
          canvas.restore();
        }

        for (final metric in path.computeMetrics()) {
          const dash = 10.0;
          const gap = 16.0;
          var distance = 0.0;
          var i = 0;
          while (distance < metric.length) {
            final start = distance;
            final end = (distance + dash).clamp(0.0, metric.length);
            final seg = metric.extractPath(start, end);
            final mid = (start + end) / 2;
            final tangent = metric.getTangentForOffset(mid);
            if (tangent != null) {
              final t = tangent.vector;
              final tLen = t.distance;
              if (tLen > 0.001) {
                final tUnit = Offset(t.dx / tLen, t.dy / tLen);
                final normal = Offset(-tUnit.dy, tUnit.dx);
                final sign = i.isEven ? 1.0 : -1.0;
                canvas.save();
                canvas.translate(
                    normal.dx * 0.9 * sign, normal.dy * 0.9 * sign);
                canvas.drawPath(seg, twistPaint);
                canvas.restore();
              }
            }
            distance += dash + gap;
            i++;
          }
        }
      }
    }
  }

  Offset _getAnchorPosition(NodeEntity node, String anchorId) {
    // Get actual rendered size
    final size = NodeUtils.getNodeSize(node, theme);
    final width = size.width * node.scale;
    final height = size.height * node.scale;

    // Pin Position Logic matching CardWidget:
    // Theme Card: margin top 8, hit area 44x44. Center Y = 8 + 22 = 30.
    // Clue/Totem Card: margin top 5, hit area 40x40. Center Y = 5 + 20 = 25.
    double pinOffsetY = 25.0;
    if (node.type == NodeType.theme) {
      pinOffsetY = 30.0;
    } else if (node.type == NodeType.totem) {
      pinOffsetY = node.styleIndex % 4 == 0 ? 25.0 : 75.0;
    } else if (node.type == NodeType.clue) {
      final assets = theme.clueCardAssets;
      if (assets.isNotEmpty) {
        final index = node.styleIndex % assets.length;
        final safeIndex = index < 0 ? 0 : index;
        final assetPath = assets[safeIndex];
        if (assetPath.contains('light')) {
          const alignmentY = -0.6;
          const pinMarginTop = 5.0;
          const pinHitSize = 40.0;
          const childHeight = pinMarginTop + pinHitSize;
          final available = height - childHeight;
          if (available > 0) {
            final offsetY = ((alignmentY + 1) / 2) * available;
            pinOffsetY = offsetY + pinMarginTop + pinHitSize / 2;
          }
        }
      }
    } else {
      pinOffsetY = 25.0;
    }

    return Offset(node.x + width / 2, node.y + pinOffsetY);
  }

  @override
  bool shouldRepaint(covariant EdgesPainter oldDelegate) {
    return true; // Or optimize based on inputs
  }
}
