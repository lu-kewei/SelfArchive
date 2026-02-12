# 数据模型设计 (Dart/Isar)

## NodeEntity (卡片)
```dart
@collection
class NodeEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  late String id;

  @Enumerated(EnumType.name)
  late NodeType type; // totem, theme, clue

  late String content; // 文本内容
  
  late double x; // 世界坐标 X
  late double y; // 世界坐标 Y
  int zIndex = 0;
  double scale = 1.0;
  double rotation = 0.0;

  @Enumerated(EnumType.name)
  late CardShape shape; // rectResizable, circle, hexagon, irregular

  double? width;  // 仅 rectResizable 使用
  double? height; // 仅 rectResizable 使用

  String? themeId; // 仅 ThemeCard 使用 (如 "like")
  List<String>? tags; // 仅 ClueCard 使用，存储关联的 themeId

  bool isPinned = false;
  bool isArchived = false;
  int archivedAt = 0;

  int styleIndex = 0;

  @ignore
  bool isEditing = false;

  @ignore
  bool isSelected = false;

  @ignore
  bool isDragging = false;
}
```

## EdgeEntity (连线)
```dart
@embedded
class AnchorRef {
  late String nodeId;
  late String anchorId; // 默认 "main"
}

@collection
class EdgeEntity {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  late String id;

  late AnchorRef from;
  late AnchorRef to;

  late String style; // 来自 ThemePack

  int createdAt = 0;
  bool visible = true;
}
```

## BoardState (Riverpod State)
```dart
@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    @Default([]) List<NodeEntity> nodes,
    @Default([]) List<EdgeEntity> edges,
    required CameraState camera,
    required ThemePack theme,
    @Default(3000.0) double boardWidth,
    @Default(1800.0) double boardHeight,
    @Default(false) bool isLoading,
    String? selectedNodeId,
  }) = _BoardState;
}
```
