class AnchorRef {
  late String nodeId;
  late String anchorId; // default "main"

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'anchorId': anchorId,
      };

  static AnchorRef fromJson(Map<String, dynamic> json) => AnchorRef()
    ..nodeId = json['nodeId'] as String
    ..anchorId = json['anchorId'] as String;
}

class EdgeEntity {
  late String id;

  late AnchorRef from;
  late AnchorRef to;

  late String style; // from themePack

  int createdAt = 0;

  bool visible = true;

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from.toJson(),
        'to': to.toJson(),
        'style': style,
        'createdAt': createdAt,
        'visible': visible,
      };

  static EdgeEntity fromJson(Map<String, dynamic> json) => EdgeEntity()
    ..id = json['id'] as String
    ..from = AnchorRef.fromJson((json['from'] as Map).cast<String, dynamic>())
    ..to = AnchorRef.fromJson((json['to'] as Map).cast<String, dynamic>())
    ..style = json['style'] as String
    ..createdAt = json['createdAt'] as int? ?? 0
    ..visible = json['visible'] as bool? ?? true;
}
