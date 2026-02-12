import 'dart:convert';
import 'dart:typed_data';

class ImageBlock {
  final String id;
  final Uint8List bytes;
  final double width;
  final double height;

  ImageBlock({
    required this.id,
    required this.bytes,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bytes': base64Encode(bytes),
        'width': width,
        'height': height,
      };

  static ImageBlock fromJson(Map<String, dynamic> json) => ImageBlock(
        id: json['id'] as String,
        bytes: base64Decode(json['bytes'] as String),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );
}

enum NodeType { totem, theme, clue }

enum CardShape { rectResizable, circle, hexagon, irregular }

enum TextFontPreset { rational, vintage, handwriting }

enum TextSizePreset { small, medium, large }

class TextStyleSpec {
  late TextFontPreset font; // Default: rational

  late TextSizePreset size; // Default: medium

  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool highlight = false;

  TextStyleSpec({
    this.font = TextFontPreset.rational,
    this.size = TextSizePreset.medium,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.highlight = false,
  });

  TextStyleSpec copyWith({
    TextFontPreset? font,
    TextSizePreset? size,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? highlight,
  }) {
    return TextStyleSpec(
      font: font ?? this.font,
      size: size ?? this.size,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      highlight: highlight ?? this.highlight,
    );
  }

  Map<String, dynamic> toJson() => {
        'font': font.name,
        'size': size.name,
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'highlight': highlight,
      };

  static TextStyleSpec fromJson(Map<String, dynamic> json) => TextStyleSpec(
        font: TextFontPreset.values.byName(json['font'] as String),
        size: TextSizePreset.values.byName(json['size'] as String),
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        underline: json['underline'] as bool? ?? false,
        highlight: json['highlight'] as bool? ?? false,
      );
}

class TextSpanSpec {
  String? text;
  TextStyleSpec? style;

  TextSpanSpec({
    this.text,
    this.style,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'style': style?.toJson(),
      };

  static TextSpanSpec fromJson(Map<String, dynamic> json) => TextSpanSpec(
        text: json['text'] as String?,
        style: json['style'] == null
            ? null
            : TextStyleSpec.fromJson(
                (json['style'] as Map).cast<String, dynamic>()),
      );
}

class NodeEntity {
  late String id;

  late NodeType type;

  late String content; // JSON or simple text

  late double x;
  late double y;

  int zIndex = 0;

  double scale = 1.0;

  double textScale = 1.0;

  double rotation = 0.0;

  late CardShape shape;

  // For rectResizable
  double? width;
  double? height;

  String? themeId; // For ThemeCard

  List<String>? tags; // For ClueCard

  bool isPinned = false; // "pinned" state

  bool isArchived = false;

  int archivedAt = 0;

  int createdAt = 0;

  // Visual style index (e.g. which frame or paper texture to use)
  // Maps to ThemePack.themeFrameAssets or ThemePack.clueCardAssets index
  int styleIndex = 0;

  // Text Styling (New)
  TextStyleSpec textStyle = TextStyleSpec();

  // Rich Text Spans (Optional, overrides content if present)
  List<TextSpanSpec>? textSpans;

  // Bottom Content (Displayed after images)
  String? bottomContent;
  List<TextSpanSpec>? bottomTextSpans;

  // Runtime state (not persisted in DB)
  bool isEditing = false;

  bool isStyleMode = false; // Toggles text style toolbar

  bool isSelected = false;

  bool isDragging = false;

  TextStyleSpec? composingTextStyle; // Transient style for rich text editing

  List<ImageBlock> images = [];

  NodeEntity copyWith({
    String? id,
    NodeType? type,
    String? content,
    double? x,
    double? y,
    int? zIndex,
    double? scale,
    double? textScale,
    double? rotation,
    CardShape? shape,
    double? width,
    double? height,
    String? themeId,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    int? archivedAt,
    int? createdAt,
    int? styleIndex,
    TextStyleSpec? textStyle,
    List<TextSpanSpec>? textSpans,
    String? bottomContent,
    List<TextSpanSpec>? bottomTextSpans,
    bool? isEditing,
    bool? isStyleMode,
    bool? isSelected,
    bool? isDragging,
    TextStyleSpec? composingTextStyle,
    List<ImageBlock>? images,
  }) {
    return NodeEntity()
      ..id = id ?? this.id
      ..type = type ?? this.type
      ..content = content ?? this.content
      ..x = x ?? this.x
      ..y = y ?? this.y
      ..zIndex = zIndex ?? this.zIndex
      ..scale = scale ?? this.scale
      ..textScale = textScale ?? this.textScale
      ..rotation = rotation ?? this.rotation
      ..shape = shape ?? this.shape
      ..width = width ?? this.width
      ..height = height ?? this.height
      ..themeId = themeId ?? this.themeId
      ..tags = tags ?? this.tags
      ..isPinned = isPinned ?? this.isPinned
      ..isArchived = isArchived ?? this.isArchived
      ..archivedAt = archivedAt ?? this.archivedAt
      ..createdAt = createdAt ?? this.createdAt
      ..styleIndex = styleIndex ?? this.styleIndex
      ..textStyle = textStyle ?? this.textStyle
      ..textSpans = textSpans ?? this.textSpans
      ..bottomContent = bottomContent ?? this.bottomContent
      ..bottomTextSpans = bottomTextSpans ?? this.bottomTextSpans
      ..isEditing = isEditing ?? this.isEditing
      ..isStyleMode = isStyleMode ?? this.isStyleMode
      ..isSelected = isSelected ?? this.isSelected
      ..isDragging = isDragging ?? this.isDragging
      ..composingTextStyle = composingTextStyle ?? this.composingTextStyle
      ..images = images ?? this.images;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'x': x,
        'y': y,
        'zIndex': zIndex,
        'scale': scale,
        'textScale': textScale,
        'rotation': rotation,
        'shape': shape.name,
        'width': width,
        'height': height,
        'themeId': themeId,
        'tags': tags,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'archivedAt': archivedAt,
        'createdAt': createdAt,
        'styleIndex': styleIndex,
        'textStyle': textStyle.toJson(),
        'textSpans': textSpans?.map((e) => e.toJson()).toList(),
        'bottomContent': bottomContent,
        'bottomTextSpans': bottomTextSpans?.map((e) => e.toJson()).toList(),
        'images': images.map((e) => e.toJson()).toList(),
      };

  static NodeEntity fromJson(Map<String, dynamic> json) {
    final node = NodeEntity()
      ..id = json['id'] as String
      ..type = NodeType.values.byName(json['type'] as String)
      ..content = json['content'] as String
      ..x = (json['x'] as num).toDouble()
      ..y = (json['y'] as num).toDouble()
      ..zIndex = json['zIndex'] as int? ?? 0
      ..scale = (json['scale'] as num?)?.toDouble() ?? 1.0
      ..textScale = (json['textScale'] as num?)?.toDouble() ?? 1.0
      ..rotation = (json['rotation'] as num?)?.toDouble() ?? 0.0
      ..shape = CardShape.values
          .byName(json['shape'] as String? ?? CardShape.rectResizable.name)
      ..width = (json['width'] as num?)?.toDouble()
      ..height = (json['height'] as num?)?.toDouble()
      ..themeId = json['themeId'] as String?
      ..tags = (json['tags'] as List?)?.cast<String>()
      ..isPinned = json['isPinned'] as bool? ?? false
      ..isArchived = json['isArchived'] as bool? ?? false
      ..archivedAt = json['archivedAt'] as int? ?? 0
      ..createdAt = json['createdAt'] as int? ?? 0
      ..styleIndex = json['styleIndex'] as int? ?? 0
      ..textStyle = TextStyleSpec.fromJson(
          (json['textStyle'] as Map).cast<String, dynamic>())
      ..bottomContent = json['bottomContent'] as String?;

    final textSpansRaw = json['textSpans'] as List?;
    if (textSpansRaw != null) {
      node.textSpans = textSpansRaw
          .map((e) => TextSpanSpec.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    final bottomSpansRaw = json['bottomTextSpans'] as List?;
    if (bottomSpansRaw != null) {
      node.bottomTextSpans = bottomSpansRaw
          .map((e) => TextSpanSpec.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    final imagesRaw = json['images'] as List?;
    if (imagesRaw != null) {
      node.images = imagesRaw
          .map((e) => ImageBlock.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    return node;
  }
}
