import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../scene/models/node_entity.dart';
import '../scene/models/edge_entity.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService not initialized');
});

class DatabaseService {
  late final SharedPreferences _prefs;

  static const String _nodesKey = 'db_nodes_v1';
  static const String _edgesKey = 'db_edges_v1';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveNode(NodeEntity node) async {
    final nodes = await _readNodes();
    final index = nodes.indexWhere((n) => n.id == node.id);
    if (index == -1) {
      nodes.add(node);
    } else {
      nodes[index] = node;
    }
    await _writeNodes(nodes);
  }

  Future<List<NodeEntity>> getAllNodes() async {
    final nodes = await _readNodes();
    return nodes.where((n) => !n.isArchived).toList();
  }

  Future<NodeEntity?> getArchivedNode(String id) async {
    final nodes = await _readNodes();
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<NodeEntity>> getArchivedClues() async {
    final nodes = await _readNodes();
    final archived = nodes
        .where((n) => n.type == NodeType.clue && n.isArchived)
        .toList()
      ..sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
    return archived;
  }

  Future<NodeEntity?> getNode(String id) async {
    final nodes = await _readNodes();
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteNode(String id) async {
    final nodes = await _readNodes();
    nodes.removeWhere((n) => n.id == id);
    await _writeNodes(nodes);

    final edges = await _readEdges();
    edges.removeWhere((e) => e.from.nodeId == id || e.to.nodeId == id);
    await _writeEdges(edges);
  }

  Future<void> deleteEdge(String id) async {
    final edges = await _readEdges();
    edges.removeWhere((e) => e.id == id);
    await _writeEdges(edges);
  }

  Future<void> saveEdge(EdgeEntity edge) async {
    final edges = await _readEdges();
    final index = edges.indexWhere((e) => e.id == edge.id);
    if (index == -1) {
      edges.add(edge);
    } else {
      edges[index] = edge;
    }
    await _writeEdges(edges);
  }

  Future<void> saveEdges(List<EdgeEntity> edges) async {
    final current = await _readEdges();
    final byId = {for (final e in current) e.id: e};
    for (final e in edges) {
      byId[e.id] = e;
    }
    await _writeEdges(byId.values.toList());
  }

  Future<List<EdgeEntity>> getAllEdges() async {
    return await _readEdges();
  }

  Future<void> saveNodesAndEdges(
    List<NodeEntity> nodes,
    List<EdgeEntity> edges,
  ) async {
    await _writeNodes(nodes);
    await _writeEdges(edges);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_nodesKey);
    await _prefs.remove(_edgesKey);
  }

  Future<List<NodeEntity>> _readNodes() async {
    final raw = _prefs.getString(_nodesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((e) => NodeEntity.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> _writeNodes(List<NodeEntity> nodes) async {
    final raw = jsonEncode(nodes.map((n) => n.toJson()).toList());
    await _prefs.setString(_nodesKey, raw);
  }

  Future<List<EdgeEntity>> _readEdges() async {
    final raw = _prefs.getString(_edgesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((e) => EdgeEntity.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> _writeEdges(List<EdgeEntity> edges) async {
    final raw = jsonEncode(edges.map((e) => e.toJson()).toList());
    await _prefs.setString(_edgesKey, raw);
  }
}
