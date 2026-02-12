import 'package:flutter/material.dart';
import '../../../scene/models/node_entity.dart';

class ResizableImageWidget extends StatefulWidget {
  final ImageBlock block;
  final Function(ImageBlock) onUpdate;
  final VoidCallback onDelete;
  final bool readOnly;

  const ResizableImageWidget({
    super.key,
    required this.block,
    required this.onUpdate,
    required this.onDelete,
    this.readOnly = false,
  });

  @override
  State<ResizableImageWidget> createState() => _ResizableImageWidgetState();
}

class _ResizableImageWidgetState extends State<ResizableImageWidget> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.readOnly) {
          setState(() {
            _isSelected = !_isSelected;
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Image Container
          Container(
            width: widget.block.width,
            height: widget.block.height,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSelected ? Colors.blue : Colors.black12,
                width: _isSelected ? 2 : 1,
              ),
              color: Colors.white,
            ),
            child: Image.memory(widget.block.bytes, fit: BoxFit.contain),
          ),

          // Delete Button (Top Right)
          if (_isSelected && !widget.readOnly)
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),

          // Resize Handle (Bottom Right)
          if (_isSelected && !widget.readOnly)
            Positioned(
              bottom: -8,
              right: -8,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final newWidth = widget.block.width + details.delta.dx;
                  final newHeight = widget.block.height + details.delta.dy;

                  // Minimum size constraint
                  if (newWidth > 50 && newHeight > 50) {
                    widget.onUpdate(ImageBlock(
                      id: widget.block.id,
                      bytes: widget.block.bytes,
                      width: newWidth,
                      height: newHeight,
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.crop_free,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
