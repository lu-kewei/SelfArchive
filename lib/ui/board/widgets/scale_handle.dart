import 'package:flutter/material.dart';
import '../utils/node_utils.dart';

class ScaleHandle extends StatelessWidget {
  final Alignment alignment;
  final Corner corner;
  final Function(Corner, Offset)? onPanStart;
  final Function(Offset)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final Color color;

  const ScaleHandle({
    super.key,
    required this.alignment,
    required this.corner,
    required this.onPanStart,
    required this.onPanUpdate,
    this.onPanEnd,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // If inside Positioned, alignment is ignored or can be used if we wrap with Align
    // But since we use child of Positioned, we just return the container.
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Allow touches on transparent area
      onPanStart: (details) => onPanStart?.call(corner, details.globalPosition),
      onPanUpdate: (details) => onPanUpdate?.call(details.globalPosition),
      onPanEnd: (_) => onPanEnd?.call(),
      child: Container(
        width: 60, // Larger hit area
        height: 60,
        color: Colors.transparent, // Ensure touch events are captured
        alignment: Alignment.center,
        child: Container(
          width: 24, // Slightly larger visual size
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
