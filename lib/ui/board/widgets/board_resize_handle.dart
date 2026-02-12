import 'dart:math' as math;
import 'package:flutter/material.dart';

class BoardResizeHandle extends StatefulWidget {
  final double width;
  final double height;
  final Function(double, double) onResize;
  final VoidCallback onResizeEnd;
  final bool isResizing;
  final VoidCallback onDoubleTapEdge;

  const BoardResizeHandle({
    super.key,
    required this.width,
    required this.height,
    required this.onResize,
    required this.onResizeEnd,
    required this.isResizing,
    required this.onDoubleTapEdge,
  });

  @override
  State<BoardResizeHandle> createState() => _BoardResizeHandleState();
}

class _BoardResizeHandleState extends State<BoardResizeHandle> {
  // We use this to detect drags on corners
  void _onPanUpdate(DragUpdateDetails details, bool isRight, bool isBottom) {
    double dx = details.delta.dx;
    double dy = details.delta.dy;

    final ratio = widget.width / widget.height;
    double scale = 1.0;

    if (isRight && isBottom) {
      final scaleX = (widget.width + dx) / widget.width;
      final scaleY = (widget.height + dy) / widget.height;
      scale = math.max(scaleX, scaleY);
    } else if (isRight) {
      scale = (widget.width + dx) / widget.width;
    } else if (isBottom) {
      scale = (widget.height + dy) / widget.height;
    }

    const minWidth = 1000.0;
    const minHeight = 600.0;
    final minScale =
        math.max(minWidth / widget.width, minHeight / widget.height);
    if (scale < minScale) scale = minScale;

    final newWidth = widget.width * scale;
    final newHeight = newWidth / ratio;

    widget.onResize(newWidth, newHeight);
  }

  Widget _buildEdgeDetector() {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTapEdge,
      behavior: HitTestBehavior.translucent,
      child: Container(color: Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Edge Detectors (Always Active)
        // Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: _buildEdgeDetector(),
        ),
        // Bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: _buildEdgeDetector(),
        ),
        // Left
        Positioned(
          top: 80,
          bottom: 80,
          left: 0,
          width: 80,
          child: _buildEdgeDetector(),
        ),
        // Right
        Positioned(
          top: 80,
          bottom: 80,
          right: 0,
          width: 80,
          child: _buildEdgeDetector(),
        ),

        // Resize UI (Only when resizing)
        if (widget.isResizing) ...[
          // Border
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.5),
                    width: 8,
                  ),
                ),
              ),
            ),
          ),

          // Right Handle (Vertical Bar)
          Positioned(
            right: 0,
            top: 0,
            bottom: 40, // Leave space for corner
            width: 40,
            child: GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, true, false),
              onPanEnd: (_) => widget.onResizeEnd(),
              child: Container(
                color: Colors.transparent,
                child: const Center(
                  child: Icon(Icons.drag_handle, color: Colors.blue, size: 24),
                ),
              ),
            ),
          ),

          // Bottom Handle (Horizontal Bar)
          Positioned(
            left: 0,
            right: 40,
            bottom: 0,
            height: 40,
            child: GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, false, true),
              onPanEnd: (_) => widget.onResizeEnd(),
              child: Container(
                color: Colors.transparent,
                child: const Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child:
                        Icon(Icons.drag_handle, color: Colors.blue, size: 24),
                  ),
                ),
              ),
            ),
          ),

          // Corner Handle (Bottom-Right)
          Positioned(
            right: 0,
            bottom: 0,
            width: 40,
            height: 40,
            child: GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, true, true),
              onPanEnd: (_) => widget.onResizeEnd(),
              child: Container(
                color: Colors.blue,
                child: const Icon(Icons.open_in_full,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
