import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../scene/models/node_entity.dart';
import '../../../core/theme/theme_pack.dart';
import '../utils/node_utils.dart';
import 'scale_handle.dart';
import 'inline_text_editor.dart';
import 'card_text_clipper.dart';
// import 'text_style_toolbar.dart'; // Removed local toolbar

class CardWidget extends StatelessWidget {
  final NodeEntity node;
  final double scale;
  final ThemePack theme;
  final Function(String)? onContentChanged;
  final Function(String)? onBottomContentChanged;
  final Function(List<TextSpanSpec>)? onBottomSpansChanged;
  final Function(List<TextSpanSpec>)? onSpansChanged; // New callback
  final VoidCallback? onEditExit;
  final VoidCallback? onDelete;
  final Function(String)? onDeleteImage;
  final Function(ImageBlock)? onUpdateImage;
  // final Function(TextStyleSpec)? onStyleChanged; // Removed, handled globally
  // final VoidCallback? onToggleStyleMode; // Removed, handled globally

  // Pin drag callbacks
  final Function(Offset globalPosition)? onPinDragStart;
  final Function(Offset localPosition, Offset globalPosition)? onPinDragUpdate;
  final Function(Offset globalPosition)? onPinDragEnd;

  // Scale Handle Callbacks
  final Function(Corner corner, Offset globalPosition)? onHandlePanStart;
  final Function(Offset globalPosition)? onHandlePanUpdate;
  final VoidCallback? onHandlePanEnd;
  final Duration animationDuration;
  final bool isPinSelected; // Add this
  final VoidCallback? onPinTap; // Add this

  const CardWidget({
    super.key,
    required this.node,
    required this.scale,
    required this.theme,
    this.animationDuration = const Duration(milliseconds: 200),
    this.isPinSelected = false, // Default false
    this.onPinTap, // Default null
    this.onContentChanged,
    this.onBottomContentChanged,
    this.onSpansChanged,
    this.onBottomSpansChanged,
    this.onEditExit,
    this.onDelete,
    this.onDeleteImage,
    this.onUpdateImage,
    // this.onStyleChanged,
    // this.onToggleStyleMode,
    this.onPinDragStart,
    this.onPinDragUpdate,
    this.onPinDragEnd,
    this.onHandlePanStart,
    this.onHandlePanUpdate,
    this.onHandlePanEnd,
  });

  TextStyle _convertStyle(TextStyleSpec? spec, double baseFontSize) {
    if (spec == null) return TextStyle(fontSize: baseFontSize);

    // Font Family
    String? fontFamily;
    if (spec.font == TextFontPreset.vintage) {
      fontFamily = GoogleFonts.zcoolXiaoWei().fontFamily;
    } else if (spec.font == TextFontPreset.handwriting) {
      fontFamily = GoogleFonts.maShanZheng().fontFamily;
    } else if (spec.font == TextFontPreset.rational) {
      fontFamily = GoogleFonts.notoSansSc().fontFamily;
    }

    // Font Size Calculation
    double fontSize = baseFontSize;
    if (spec.size == TextSizePreset.small) {
      fontSize = baseFontSize * 0.80;
    } else if (spec.size == TextSizePreset.large) {
      fontSize = baseFontSize * 1.75;
    }

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: spec.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: spec.italic ? FontStyle.italic : FontStyle.normal,
      decoration:
          spec.underline ? TextDecoration.underline : TextDecoration.none,
      backgroundColor:
          spec.highlight ? Colors.yellow.withValues(alpha: 0.3) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    late CardStyle style;
    BoxShape shape = BoxShape.rectangle;
    BorderRadius? borderRadius = BorderRadius.circular(8);

    switch (node.type) {
      case NodeType.totem:
        style = theme.totemStyle;
        // Don't force circle shape for Totem if we have assets
        // Let the asset decide, or default to rectangle
        shape = BoxShape.rectangle;
        borderRadius = null;
        break;
      case NodeType.theme:
        style = theme.themeStyle;
        break;
      case NodeType.clue:
        style = theme.clueStyle;
        break;
    }

    if (node.shape == CardShape.circle && node.type != NodeType.totem) {
      shape = BoxShape.circle;
      borderRadius = null;
    }

    String? assetImage;
    if (node.type == NodeType.theme) {
      if (theme.themeFrameAssets.isNotEmpty) {
        final index = node.styleIndex % theme.themeFrameAssets.length;
        final safeIndex = index < 0 ? 0 : index;
        assetImage = theme.themeFrameAssets[safeIndex];
      } else {
        assetImage = theme.stickyNoteAsset;
      }
    } else if (node.type == NodeType.clue) {
      if (theme.clueCardAssets.isNotEmpty) {
        final index = node.styleIndex % theme.clueCardAssets.length;
        final safeIndex = index < 0 ? 0 : index;
        assetImage = theme.clueCardAssets[safeIndex];
      }
    } else if (node.type == NodeType.totem) {
      // Use styleIndex to pick from totemAssets
      if (theme.totemAssets.isNotEmpty) {
        final index = node.styleIndex % theme.totemAssets.length;
        final safeIndex = index < 0 ? 0 : index;
        assetImage = theme.totemAssets[safeIndex];
      }
    } else if (style.textureAsset != null) {
      assetImage = style.textureAsset;
    }
    final bool isNonCreamTotem =
        node.type == NodeType.totem && node.styleIndex % 4 != 0;

    Size size = NodeUtils.getNodeSize(node, theme);
    final baseWidth = size.width;
    final baseHeight = size.height;

    List<BoxShadow> boxShadows = [];
    if (node.type != NodeType.theme) {
      if (assetImage != null && assetImage.contains('hanging_tag')) {
        shape = BoxShape.circle;
        borderRadius = null;
      }
    }

    final showScaleHandles =
        node.isSelected && node.type == NodeType.clue && !node.isEditing;

    // Define handle hit radius (half of handle size)
    const double handleHitRadius = 30.0;

    // Helper to get effective style
    TextStyle getEffectiveTextStyle() {
      final spec = node.textStyle;

      // Font Family
      String? fontFamily = style.fontFamily;
      if (spec.font == TextFontPreset.vintage) {
        fontFamily = GoogleFonts.zcoolXiaoWei().fontFamily;
      } else if (spec.font == TextFontPreset.handwriting) {
        fontFamily = GoogleFonts.maShanZheng().fontFamily;
      } else if (spec.font == TextFontPreset.rational) {
        fontFamily = GoogleFonts.notoSansSc().fontFamily;
      }

      // Font Size
      double fontSize = style.fontSize;
      if (spec.size == TextSizePreset.small) {
        fontSize *= 0.80;
      } else if (spec.size == TextSizePreset.large) {
        fontSize *= 1.75;
      }

      // Apply Node textScale
      fontSize *= node.textScale;

      return TextStyle(
        fontSize: fontSize,
        color: style.textColor,
        fontFamily: fontFamily,
        fontWeight: spec.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: spec.italic ? FontStyle.italic : FontStyle.normal,
        decoration:
            spec.underline ? TextDecoration.underline : TextDecoration.none,
        backgroundColor:
            spec.highlight ? Colors.yellow.withValues(alpha: 0.3) : null,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Style Toolbar Removed (Moved to Global)

        // Main Card Content with Margin
        Container(
          margin: const EdgeInsets.all(handleHitRadius),
          child: AnimatedContainer(
            duration: animationDuration,
            curve: Curves.easeInOut,
            width: baseWidth * scale,
            height: baseHeight * scale,
            decoration: BoxDecoration(
              color: assetImage != null
                  ? Colors.transparent
                  : style.backgroundColor,
              shape: shape,
              borderRadius: borderRadius,
              image: (assetImage != null && !assetImage.contains('hanging_tag'))
                  ? DecorationImage(
                      image: AssetImage(assetImage),
                      fit: BoxFit.contain,
                    )
                  : null,
              boxShadow: boxShadows,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (assetImage != null && assetImage.contains('hanging_tag'))
                  Positioned.fill(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 0), // Adjust if needed
                      child: Image.asset(
                        assetImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // Pin
                if (node.type == NodeType.theme)
                  Align(
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: onPinTap, // Pin Hit Test
                      onPanStart: (details) =>
                          onPinDragStart?.call(details.globalPosition),
                      onPanUpdate: (details) => onPinDragUpdate?.call(
                          details.localPosition, details.globalPosition),
                      onPanEnd: (details) =>
                          onPinDragEnd?.call(details.globalPosition),
                      child: Container(
                        margin: const EdgeInsets.only(
                            top: 8), // Adjusted for theme card
                        width: 44, // Expanded hit area (14 + 15*2)
                        height: 44, // Expanded hit area
                        color: Colors.transparent, // Invisible hit target
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Selection Halo
                            if (isPinSelected)
                              Container(
                                width: 28, // 14 + 14
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        Colors.red[800]!.withValues(alpha: 0.6),
                                    width: 3,
                                  ),
                                ),
                              ),
                            // Pin Visual
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color:
                                    Colors.red[800], // Darker red for theme pin
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (node.type != NodeType.theme)
                  Align(
                    alignment:
                        (assetImage != null && assetImage.contains('light'))
                            ? const Alignment(0.0,
                                -0.6) // Inset for light card transparent border
                            : Alignment.topCenter,
                    child: GestureDetector(
                      onTap: onPinTap, // Pin Hit Test
                      onPanStart: (details) =>
                          onPinDragStart?.call(details.globalPosition),
                      onPanUpdate: (details) => onPinDragUpdate?.call(
                          details.localPosition, details.globalPosition),
                      onPanEnd: (details) =>
                          onPinDragEnd?.call(details.globalPosition),
                      child: Container(
                        margin: EdgeInsets.only(top: isNonCreamTotem ? 55 : 5),
                        width: 40, // Expanded hit area (12 + 14*2)
                        height: 40,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Selection Halo
                            if (isPinSelected)
                              Container(
                                width: 24, // 12 + 12
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.accentColor
                                        .withValues(alpha: 0.6),
                                    width: 3,
                                  ),
                                ),
                              ),
                            // Pin Visual
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 1,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Content
                Positioned.fill(
                  child: ClipPath(
                    clipper:
                        CardTextClipper(node: node, assetImage: assetImage),
                    child: Padding(
                      padding: (assetImage != null &&
                              assetImage.contains('hanging_tag'))
                          ? const EdgeInsets.fromLTRB(24.0, 50.0, 24.0,
                              24.0) // Top = 36 (rope) + 14 (padding)
                          : const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                      child: node.isEditing
                          ? Center(
                              child: InlineTextEditor(
                                initialText: node.content,
                                style: style,
                                node: node,
                                textStyle:
                                    getEffectiveTextStyle(), // Pass computed style
                                onChanged: (value) {
                                  onContentChanged?.call(value);
                                },
                                onBottomChanged: (value) {
                                  onBottomContentChanged?.call(value);
                                },
                                onSpansChanged: (spans) {
                                  onSpansChanged?.call(spans);
                                },
                                onBottomSpansChanged: (spans) {
                                  onBottomSpansChanged?.call(spans);
                                },
                                onSubmitted: () {
                                  onEditExit?.call();
                                },
                                onDeleteImage: onDeleteImage,
                                onUpdateImage: onUpdateImage,
                                // onToggleStyleMode: onToggleStyleMode, // Removed
                              ),
                            )
                          : Listener(
                              // Swallow scroll events to prevent board zoom
                              onPointerSignal: (event) {
                                if (event is PointerScrollEvent) {
                                  // Allow scroll to propagate to SingleChildScrollView
                                }
                              },
                              child: Center(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      node.textSpans != null &&
                                              node.textSpans!.any((s) =>
                                                  (s.text ?? '').isNotEmpty) &&
                                              node.textSpans!
                                                      .map((s) => s.text ?? '')
                                                      .join('') ==
                                                  node.content
                                          ? RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(
                                                style: getEffectiveTextStyle(),
                                                children: node.textSpans!
                                                    .where((s) => (s.text ?? '')
                                                        .isNotEmpty)
                                                    .map((span) {
                                                  return TextSpan(
                                                    text: span.text,
                                                    style: _convertStyle(
                                                        span.style,
                                                        getEffectiveTextStyle()
                                                                .fontSize ??
                                                            14.0),
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          : Text(
                                              node.content,
                                              textAlign: TextAlign.center,
                                              style:
                                                  getEffectiveTextStyle(), // Use computed style
                                            ),
                                      if (node.images.isNotEmpty)
                                        ...node.images.map((img) => Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Container(
                                                width: img.width,
                                                height: img.height,
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.black12),
                                                  color: Colors.white,
                                                ),
                                                child: Image.memory(img.bytes,
                                                    fit: BoxFit.contain),
                                              ),
                                            )),
                                      if (node.images.isNotEmpty &&
                                          (node.bottomContent != null ||
                                              node.bottomTextSpans != null))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: node.bottomTextSpans != null &&
                                                  node.bottomTextSpans!.any(
                                                      (s) => (s.text ?? '')
                                                          .isNotEmpty) &&
                                                  node.bottomTextSpans!
                                                          .map((s) =>
                                                              s.text ?? '')
                                                          .join('') ==
                                                      (node.bottomContent ?? '')
                                              ? RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    style:
                                                        getEffectiveTextStyle(),
                                                    children: node
                                                        .bottomTextSpans!
                                                        .where((s) =>
                                                            (s.text ?? '')
                                                                .isNotEmpty)
                                                        .map((span) {
                                                      return TextSpan(
                                                        text: span.text,
                                                        style: _convertStyle(
                                                            span.style,
                                                            getEffectiveTextStyle()
                                                                    .fontSize ??
                                                                14.0),
                                                      );
                                                    }).toList(),
                                                  ),
                                                )
                                              : Text(
                                                  node.bottomContent ?? '',
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      getEffectiveTextStyle(),
                                                ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scale Handles (Positioned relative to the outer Stack)
        if (showScaleHandles) ...[
          if (!(assetImage != null && assetImage.contains('light'))) ...[
            Positioned(
              left: 0,
              top: 0,
              child: ScaleHandle(
                alignment: Alignment.center,
                corner: Corner.tl,
                onPanStart: onHandlePanStart,
                onPanUpdate: onHandlePanUpdate,
                onPanEnd: onHandlePanEnd,
                color: theme.accentColor,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: ScaleHandle(
                alignment: Alignment.center,
                corner: Corner.br,
                onPanStart: onHandlePanStart,
                onPanUpdate: onHandlePanUpdate,
                onPanEnd: onHandlePanEnd,
                color: theme.accentColor,
              ),
            ),
          ],
          // Special Scale Handles for Light cards with large transparent borders
          if (assetImage != null && assetImage.contains('light')) ...[
            Positioned(
              left: 50 * scale,
              top: 35 * scale,
              child: ScaleHandle(
                alignment: Alignment.center,
                corner: Corner.tl,
                onPanStart: onHandlePanStart,
                onPanUpdate: onHandlePanUpdate,
                onPanEnd: onHandlePanEnd,
                color: theme.accentColor,
              ),
            ),
            Positioned(
              right: 50 * scale,
              bottom: 35 * scale,
              child: ScaleHandle(
                alignment: Alignment.center,
                corner: Corner.br,
                onPanStart: onHandlePanStart,
                onPanUpdate: onHandlePanUpdate,
                onPanEnd: onHandlePanEnd,
                color: theme.accentColor,
              ),
            ),
          ],
        ],

        // Style Mode Toggle Button Removed (Moved to Global)

        // Delete Button (Positioned at Top-Right)
        if (node.isSelected && !node.isEditing && node.type != NodeType.totem)
          Positioned(
            top: (assetImage != null && assetImage.contains('light'))
                ? 18 + 35 * scale
                : 18,
            right: (assetImage != null && assetImage.contains('light'))
                ? 18 + 50 * scale
                : 18,
            child: GestureDetector(
              onTap: () {
                // Show dialog from parent if needed, or callback
                // Here we just call onDelete. Parent handles confirmation if logic is moved there.
                // But wait, BoardScreen showed dialog.
                // Let's assume onDelete shows dialog or deletes directly.
                // The BoardScreen implementation of onDelete simply calls controller.deleteNode.
                // So confirmation logic should be inside onDelete or here?
                // The user expects the dialog.
                // We should probably invoke onDelete directly and let parent decide?
                // Or we can show dialog here.
                // To keep CardWidget dumb, onDelete should probably trigger the action.
                // But previously onTap showed dialog.
                // Let's rely on onDelete callback.
                // NOTE: We need to move the Dialog logic to DraggableNode or Controller if we want it preserved.
                // Actually BoardScreen passed:
                // onDelete: () { controller.deleteNode(node.id); }
                // So if we call onDelete(), it deletes immediately.
                // We should replicate the Dialog logic here or ask BoardScreen to pass a callback that shows dialog.
                // For now, let's call onDelete.
                // Wait, if I call onDelete directly, it might be too aggressive.
                // Let's assume the callback passed is "request delete".
                // We can't easily show dialog here without context and controller.
                // But we have context.
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除卡片'),
                    content: const Text('确定要删除这张卡片吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete?.call();
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.zero,
                color: Colors.transparent, // Hit test
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
