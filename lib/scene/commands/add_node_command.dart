import '../../core/commands/base_command.dart';
import '../../storage/database_service.dart';
import '../models/node_entity.dart';
import '../models/edge_entity.dart';

class AddNodeCommand extends BaseCommand {
  final NodeEntity node;
  final List<EdgeEntity> edges;
  final DatabaseService db;
  final Function(NodeEntity, List<EdgeEntity>)? onStateUpdate;
  final Function(String, List<String>)? onUndo;

  AddNodeCommand({
    required this.node,
    this.edges = const [],
    required this.db,
    this.onStateUpdate,
    this.onUndo,
  });

  @override
  String get id => 'add_node_${node.id}';

  @override
  String get name => 'Add Node';

  @override
  DateTime get timestamp => DateTime.now();

  @override
  Future<void> execute() async {
    await db.saveNodesAndEdges([node], edges);
    onStateUpdate?.call(node, edges);
  }

  @override
  Future<void> undo() async {
    // Note: DatabaseService needs a delete method
    // For now we might have to manually delete using Isar API if not exposed
    // Or we implement a soft delete (archive)

    // Assuming we want hard delete for undo of "Add":
    // db.deleteNode(node.id);
    // db.deleteEdges(edges.map((e) => e.id).toList());

    // Since delete is not exposed in db service yet, let's just mark as archived?
    // Or better, implement delete in DB service.

    // For M1/M2 prototype, let's leave undo empty or implement delete later.
    onUndo?.call(node.id, edges.map((e) => e.id).toList());
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'AddNodeCommand',
        'nodeId': node.id,
        'edgeCount': edges.length,
      };
}
