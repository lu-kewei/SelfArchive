import '../../core/commands/base_command.dart';
import '../../storage/database_service.dart';

class MoveNodeCommand extends BaseCommand {
  final String nodeId;
  final double newX;
  final double newY;
  final double oldX;
  final double oldY;
  final DatabaseService db;

  // Optional: callback to update local state if not watching DB stream
  final Function(String, double, double)? onStateUpdate;

  MoveNodeCommand({
    required this.nodeId,
    required this.newX,
    required this.newY,
    required this.oldX,
    required this.oldY,
    required this.db,
    this.onStateUpdate,
  });

  @override
  String get id => 'move_node_$nodeId';

  @override
  String get name => 'Move Node';

  @override
  DateTime get timestamp => DateTime.now();

  @override
  Future<void> execute() async {
    // 1. Update DB
    final nodes = await db.getAllNodes(); // Optimizable: getById
    final node = nodes.firstWhere((n) => n.id == nodeId);
    node.x = newX;
    node.y = newY;
    await db.saveNode(node);

    // 2. Update State
    onStateUpdate?.call(nodeId, newX, newY);
  }

  @override
  Future<void> undo() async {
    final nodes = await db.getAllNodes();
    final node = nodes.firstWhere((n) => n.id == nodeId);
    node.x = oldX;
    node.y = oldY;
    await db.saveNode(node);

    onStateUpdate?.call(nodeId, oldX, oldY);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'MoveNodeCommand',
        'nodeId': nodeId,
        'from': {'x': oldX, 'y': oldY},
        'to': {'x': newX, 'y': newY},
      };
}
