import 'package:flutter/material.dart';
import '../../../scene/models/node_entity.dart';
import '../../../core/theme/theme_pack.dart';
import '../utils/node_utils.dart';
import 'card_widget.dart';

class DraggableNode extends StatefulWidget {
  final NodeEntity node;
  final ThemePack theme;
  final Function(double, double) onDragEnd;
  final VoidCallback onDoubleTap;
  final Function(String) onContentChanged;
  final Function(String)? onBottomContentChanged;
  final Function(List<TextSpanSpec>)? onSpansChanged;
  final Function(List<TextSpanSpec>)? onBottomSpansChanged;
  final VoidCallback onEditExit;
  final VoidCallback onDelete;
  final Function(String)? onDeleteImage;
  final Function(ImageBlock)? onUpdateImage;
  final Function(double x, double y) onDragUpdate;

  // Pin drag callbacks
  final Function(Offset globalPosition)? onPinDragStart;
  final Function(Offset localPosition, Offset globalPosition)? onPinDragUpdate;
  final Function(Offset globalPosition)? onPinDragEnd;

  // Pin tap/select
  final bool isPinSelected;
  final VoidCallback? onPinTap;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  // Scaling callbacks
  final Function(double scale, double x, double y)? onScaleEnd;

  // Coordinate conversion
  final Offset Function(Offset screenPoint) screenToWorld;

  const DraggableNode({
    super.key,
    required this.node,
    required this.theme,
    required this.onDragEnd,
    required this.onTap,
    required this.onDoubleTap,
    required this.onContentChanged,
    this.onBottomContentChanged,
    this.onSpansChanged,
    this.onBottomSpansChanged,
    required this.onEditExit,
    required this.onDelete,
    this.onDeleteImage,
    this.onUpdateImage,
    required this.onDragUpdate,
    required this.screenToWorld,
    this.onPinDragStart,
    this.onPinDragUpdate,
    this.onPinDragEnd,
    this.isPinSelected = false,
    this.onPinTap,
    this.onLongPress,
    this.onScaleEnd,
  });

  @override
  State<DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<DraggableNode> {
  late double x;
  late double y;
  double? _tempScale; // Local state for smooth scaling

  double? _initialScaleCorrection; // Ratio to correct jump on start

  // Scaling state
  Corner? _activeDragCorner;
  Corner? _activeAnchorCorner;
  Offset? _anchorWorld;

  @override
  void initState() {
    super.initState();
    x = widget.node.x;
    y = widget.node.y;
  }

  @override
  void didUpdateWidget(DraggableNode oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.node.x != oldWidget.node.x ||
        widget.node.y != oldWidget.node.y) {
      // Only update local x/y if we are NOT dragging/scaling locally
      // Actually DraggableNode is rebuilt when parent state changes.
      // If we are dragging, we want to keep local state.
      // But usually parent updates only on DragEnd.
      if (_activeDragCorner == null) {
        x = widget.node.x;
        y = widget.node.y;
      }
    }
  }

  Corner _opposite(Corner c) {
    switch (c) {
      case Corner.tl:
        return Corner.br;
      case Corner.tr:
        return Corner.bl;
      case Corner.bl:
        return Corner.tr;
      case Corner.br:
        return Corner.tl;
    }
  }

  Offset _cornerOf(Rect r, Corner c) {
    switch (c) {
      case Corner.tl:
        return r.topLeft;
      case Corner.tr:
        return r.topRight;
      case Corner.bl:
        return r.bottomLeft;
      case Corner.br:
        return r.bottomRight;
    }
  }

  void _onHandlePanStart(Corner dragCorner, Offset globalPosition) {
    final currentScale = _tempScale ?? widget.node.scale;

    // Use the same logic for baseSize as in update and build
    Size size = NodeUtils.getNodeSize(widget.node, widget.theme);

    final width = size.width * currentScale;
    final height = size.height * currentScale;

    // Current world rect based on local x/y
    final rect = Rect.fromLTWH(x, y, width, height);

    // Calculate initial correction to prevent jump
    // We simulate a "scale" calculation based on current pointer
    // and find the ratio between current real scale and what the formula would return.
    final worldP = widget.screenToWorld(globalPosition);
    final anchorCorner = _opposite(dragCorner);
    final anchor = _cornerOf(rect, anchorCorner);

    // We use a huge maxScale to get the "raw" geometric scale without clamping
    final rawScale = _computeUniformScale(
      anchor: anchor,
      pointer: worldP,
      baseSize: size,
      minScale: 0.0001,
      maxScale: 10000.0,
    );

    double correction = 1.0;
    if (rawScale > 0.0001) {
      correction = currentScale / rawScale;
    }

    setState(() {
      _initialScaleCorrection = correction;
      _activeDragCorner = dragCorner;
      _activeAnchorCorner = anchorCorner;
      _anchorWorld = anchor;
    });
  }

  void _onHandlePanUpdate(Offset globalPosition) {
    if (_anchorWorld == null || _activeAnchorCorner == null) return;

    final worldP = widget.screenToWorld(globalPosition);
    // Re-calculate base size here to match build logic
    // This is important because build() might override size for hanging_tag
    Size baseSize = NodeUtils.getNodeSize(widget.node, widget.theme);

    double s = _computeUniformScale(
      anchor: _anchorWorld!,
      pointer: worldP,
      baseSize: baseSize,
      minScale: 0.0001, // Don't clamp min/max yet, apply correction first
      maxScale: 10000.0,
    );

    // Apply initial offset correction
    if (_initialScaleCorrection != null) {
      s = s * _initialScaleCorrection!;
    }

    // Now clamp to valid range
    s = s.clamp(0.5, 3.0);

    final newWidth = baseSize.width * s;
    final newHeight = baseSize.height * s;
    final newSize = Size(newWidth, newHeight);

    final newTopLeft = _topLeftFromAnchor(
      anchor: _anchorWorld!,
      anchorCorner: _activeAnchorCorner!,
      scaledSize: newSize,
    );

    setState(() {
      _tempScale = s;
      x = newTopLeft.dx;
      y = newTopLeft.dy;
    });
  }

  void _onHandlePanEnd() {
    if (_tempScale != null) {
      widget.onScaleEnd?.call(_tempScale!, x, y);

      setState(() {
        _activeDragCorner = null;
        _activeAnchorCorner = null;
        _anchorWorld = null;
        _tempScale = null;
      });
    }
  }

  // Ensure minScale is respected (0.5)
  // Ensure maxScale is respected (3.0)
  // Ensure aspect ratio is maintained (handled by single scale factor)
  double _computeUniformScale({
    required Offset anchor,
    required Offset pointer,
    required Size baseSize,
    required double minScale,
    required double maxScale,
  }) {
    final double dx = (pointer.dx - anchor.dx).abs();
    final double dy = (pointer.dy - anchor.dy).abs();

    // Avoid 0
    final double wCandidate = dx < 1.0 ? 1.0 : dx;
    final double hCandidate = dy < 1.0 ? 1.0 : dy;

    final double sFromW = wCandidate / baseSize.width;
    final double sFromH = hCandidate / baseSize.height;

    double s = sFromW > sFromH ? sFromW : sFromH;

    return s.clamp(minScale, maxScale);
  }

  Offset _topLeftFromAnchor({
    required Offset anchor,
    required Corner anchorCorner,
    required Size scaledSize,
  }) {
    final double w = scaledSize.width;
    final double h = scaledSize.height;

    switch (anchorCorner) {
      case Corner.tl:
        return anchor;
      case Corner.tr:
        return Offset(anchor.dx - w, anchor.dy);
      case Corner.bl:
        return Offset(anchor.dx, anchor.dy - h);
      case Corner.br:
        return Offset(anchor.dx - w, anchor.dy - h);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate offset to simulate position change during scaling
    // Since parent Positioned uses widget.node.x/y, we need to translate by (local x - widget.node.x)
    final dx = x - widget.node.x;
    final dy = y - widget.node.y;

    // Hardcoded handle hit radius from CardWidget
    const double handleHitRadius = 30.0;

    return Transform.translate(
        offset: Offset(dx - handleHitRadius, dy - handleHitRadius),
        child: GestureDetector(
          behavior:
              HitTestBehavior.translucent, // Allow taps to pass if not handled
          onPanUpdate: (details) {
            // If scaling is active, ignore parent drag to prevent conflict
            if (_activeDragCorner != null) return;

            setState(() {
              x += details.delta.dx;
              y += details.delta.dy;
            });
            widget.onDragUpdate(x, y); // Report drag update
          },
          onPanEnd: (details) {
            if (_activeDragCorner != null) return;
            widget.onDragEnd(x, y);
          },
          onDoubleTap: widget.onDoubleTap,
          // Remove onTap here to allow it to bubble up to CardWidget or handle it explicitly
          // If we handle onTap here, it might consume the event.
          // Actually, DraggableNode wraps CardWidget.
          // If CardWidget has interactive elements (TextField), they handle tap.
          // If CardWidget background is tapped, we want to select the node.
          // If we tap OUTSIDE any node (on Board), we want to deselect.
          // The issue is: DraggableNode's GestureDetector might be claiming the stream.
          // Let's keep onTap but ensure it doesn't block child hits if needed?
          // No, GestureDetector competes.
          // However, if we are in "Scale Mode" (isSelected=true), and we tap outside,
          // the BoardScreen's background tap should catch it.
          // BUT if we tap THIS node, we want to keep it selected.
          // The user says: "Click card to enter scale mode" -> OK.
          // "Click OUTSIDE card to exit" -> This is the problem.
          // Currently BoardScreen has a GestureDetector for background.
          // If that is not working, it means something else is consuming the tap.
          // Maybe InteractiveViewer?
          // Or maybe the node itself is covering the area? No.
          // Wait, if I tap outside, BoardScreen's onTap should fire selectNode(null).
          // Let's verify BoardScreen's background detector.
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: CardWidget(
            node: widget.node,
            scale: _tempScale ?? widget.node.scale,
            theme: widget.theme,
            animationDuration: _activeDragCorner != null
                ? Duration.zero
                : const Duration(milliseconds: 200),
            onContentChanged: widget.onContentChanged,
            onBottomContentChanged: widget.onBottomContentChanged,
            onSpansChanged: widget.onSpansChanged,
            onBottomSpansChanged: widget.onBottomSpansChanged,
            onEditExit: widget.onEditExit,
            onDelete: widget.onDelete,
            onDeleteImage: widget.onDeleteImage,
            onUpdateImage: widget.onUpdateImage,
            onPinDragStart: widget.onPinDragStart,
            onPinDragUpdate: widget.onPinDragUpdate,
            onPinDragEnd: widget.onPinDragEnd,
            isPinSelected: widget.isPinSelected,
            onPinTap: widget.onPinTap,

            // Pass Handle Callbacks
            onHandlePanStart: _onHandlePanStart,
            onHandlePanUpdate: _onHandlePanUpdate,
            onHandlePanEnd: _onHandlePanEnd,
          ),
        ));
  }
}
