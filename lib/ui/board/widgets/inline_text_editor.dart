import 'package:flutter/material.dart';
import '../../../scene/models/node_entity.dart';
import '../../../core/theme/theme_pack.dart';
import 'rich_text_controller.dart';
import 'resizable_image_widget.dart'; // Import

class InlineTextEditor extends StatefulWidget {
  final String initialText;
  final CardStyle style;
  final NodeEntity node;
  final TextStyle? textStyle; // Base style
  final ValueChanged<String>? onChanged; // Top content changed
  final ValueChanged<String>? onBottomChanged; // Bottom content changed
  final Function(List<TextSpanSpec>)? onSpansChanged; // Top spans
  final Function(List<TextSpanSpec>)? onBottomSpansChanged; // Bottom spans
  final VoidCallback onSubmitted;
  final VoidCallback? onToggleStyleMode;
  final Function(String)? onDeleteImage;
  final Function(ImageBlock)? onUpdateImage;

  const InlineTextEditor({
    super.key,
    required this.initialText,
    required this.style,
    required this.node,
    this.textStyle,
    this.onChanged,
    this.onBottomChanged,
    this.onSpansChanged,
    this.onBottomSpansChanged,
    required this.onSubmitted,
    this.onToggleStyleMode,
    this.onDeleteImage,
    this.onUpdateImage,
  });

  @override
  State<InlineTextEditor> createState() => _InlineTextEditorState();
}

class _InlineTextEditorState extends State<InlineTextEditor> {
  late RichTextEditingController _controller;
  RichTextEditingController? _bottomController;
  final FocusNode _topFocus = FocusNode();
  final FocusNode _bottomFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = RichTextEditingController(
      text: widget.initialText,
      initialSpans: widget.node.textSpans,
      defaultStyle: widget.node.textStyle,
      onSpansChanged: (spans) {
        widget.onSpansChanged?.call(spans);
        final fullText = spans.map((s) => s.text ?? '').join('');
        if (fullText != widget.node.content) {
          widget.onChanged?.call(fullText);
        }
      },
    );

    if (widget.node.images.isNotEmpty) {
      _initBottomController();
    }
  }

  void _initBottomController() {
    if (_bottomController != null) return;
    _bottomController = RichTextEditingController(
      text: widget.node.bottomContent,
      initialSpans: widget.node.bottomTextSpans,
      defaultStyle: widget.node.textStyle,
      onSpansChanged: (spans) {
        widget.onBottomSpansChanged?.call(spans);
        final fullText = spans.map((s) => s.text ?? '').join('');
        if (fullText != widget.node.bottomContent) {
          widget.onBottomChanged?.call(fullText);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bottomController?.dispose();
    _topFocus.dispose();
    _bottomFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InlineTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.composingTextStyle != oldWidget.node.composingTextStyle) {
      _controller.setComposingStyle(widget.node.composingTextStyle);
      _bottomController?.setComposingStyle(widget.node.composingTextStyle);
    }

    // Also update base style if changed (e.g. font size change from toolbar)
    if (widget.textStyle != oldWidget.textStyle && widget.textStyle != null) {
      // Force rebuild/update of style in controller?
      // RichTextEditingController uses defaultStyle.
      // We should update it.
      // Convert Flutter TextStyle back to TextStyleSpec is hard here.
      // Wait, _controller.defaultStyle expects TextStyleSpec.
      // But widget.textStyle is Flutter TextStyle.
      // This is a type mismatch.
      // widget.textStyle is passed from CardWidget as a computed Flutter TextStyle.
      // RichTextEditingController.defaultStyle is TextStyleSpec.

      // We cannot easily convert TextStyle back to TextStyleSpec without losing info or complexity.
      // However, RichTextEditingController uses defaultStyle ONLY to init spans if null,
      // or to apply as base style? No, it uses it for new spans if no style set.

      // Actually, RichTextEditingController doesn't use defaultStyle for rendering directly,
      // the rendering is done in buildTextSpan using _convertStyle.
      // The `defaultStyle` field in controller is used for `_defaultStyle` which is `TextStyleSpec`.

      // The issue is: we are trying to assign `widget.textStyle` (TextStyle) to `_controller.defaultStyle` (TextStyleSpec).
      // We should pass `widget.node.textStyle` (TextStyleSpec) to update the controller's default spec.

      // Correct approach: use node.textStyle
      _controller.defaultStyle = widget.node.textStyle;
      _bottomController?.defaultStyle = widget.node.textStyle;
    }

    // Initialize bottom controller if images added
    if (widget.node.images.isNotEmpty && _bottomController == null) {
      _initBottomController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                focusNode: _topFocus,
                autofocus: true,
                maxLines: null,
                textAlign: TextAlign.center,
                style: widget.textStyle ??
                    TextStyle(
                      fontSize: (widget.node.type == NodeType.theme ? 16 : 12) *
                          widget.node.textScale,
                      color: widget.style.textColor,
                      fontFamily: widget.style.fontFamily,
                      fontWeight: widget.node.type == NodeType.totem ||
                              widget.node.type == NodeType.theme
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  widget.onChanged?.call(value);
                },
                onSubmitted: (_) {
                  if (_bottomController != null) {
                    _bottomFocus.requestFocus();
                  } else {
                    widget.onSubmitted();
                  }
                },
              ),
              if (widget.node.images.isNotEmpty)
                ...widget.node.images.map((img) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ResizableImageWidget(
                        block: img,
                        onUpdate: (newBlock) {
                          widget.onUpdateImage?.call(newBlock);
                        },
                        onDelete: () {
                          widget.onDeleteImage?.call(img.id);
                        },
                      ),
                    )),
              if (_bottomController != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _bottomController,
                    focusNode: _bottomFocus,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: widget.textStyle ??
                        TextStyle(
                          fontSize:
                              (widget.node.type == NodeType.theme ? 16 : 12) *
                                  widget.node.textScale,
                          color: widget.style.textColor,
                          fontFamily: widget.style.fontFamily,
                          fontWeight: widget.node.type == NodeType.totem ||
                                  widget.node.type == NodeType.theme
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      widget.onBottomChanged?.call(value);
                    },
                    onSubmitted: (_) {
                      widget.onSubmitted();
                    },
                  ),
                ),
            ],
          ),
        ),
        // Style Mode Toggle Button (Floating "T" button inside editor area)
        if (widget.onToggleStyleMode != null)
          Positioned(
            right: 0,
            top: -30, // Position above or to the side
            child: GestureDetector(
              onTap: widget.onToggleStyleMode,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.node.isStyleMode
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: widget.node.isStyleMode
                      ? Border.all(color: Colors.blue)
                      : null,
                ),
                child: const Icon(Icons.title, size: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}
