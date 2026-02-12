import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/camera/camera_state.dart';
import '../../../core/commands/command_processor.dart';
import '../../../storage/database_service.dart';
import '../../../scene/models/node_entity.dart';
import '../../../scene/models/edge_entity.dart';
import '../../../scene/models/board_state.dart';
import '../../../scene/commands/add_node_command.dart';

import '../../../core/theme/theme_pack.dart';

part 'board_controller.g.dart';

@riverpod
class BoardController extends _$BoardController {
  late DatabaseService _db;
  late CommandProcessor _commandProcessor;
  Timer? _debounceTimer;

  @override
  BoardState build() {
    _db = ref.watch(databaseServiceProvider);
    _commandProcessor = ref.watch(commandProcessorProvider);

    // Clean up timer on dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // Initial Camera State
    final initialCamera = CameraState.initial();
    // Default Theme
    final initialTheme = ThemePack.vintage();

    Future.microtask(() => _loadData());
    return BoardState(
      camera: initialCamera,
      theme: initialTheme,
      isLoading: true,
    );
  }

  Future<void> _loadData() async {
    final nodes = await _db.getAllNodes();
    final edges = await _db.getAllEdges();

    // Load Camera Persistence
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Camera
      final cameraList = prefs.getStringList('camera_matrix');
      CameraState? savedCamera;
      if (cameraList != null && cameraList.length == 16) {
        final matrixList =
            cameraList.map((e) => double.tryParse(e) ?? 0.0).toList();
        final matrix = Matrix4.fromList(matrixList);
        savedCamera = CameraState(matrix);
      }

      // Load Theme
      final themeId = prefs.getString('app_theme');
      ThemePack? savedTheme;
      if (themeId != null) {
        switch (themeId) {
          case 'fresh':
            savedTheme = ThemePack.fresh();
            break;
          case 'artistic':
            savedTheme = ThemePack.artistic();
            break;
          case 'vintage':
            savedTheme = ThemePack.vintage();
            break;
        }
      }

      if (nodes.isEmpty) {
        await _initializeDefaultBoard();
        // Even if board is empty (init), apply saved theme if exists
        if (savedTheme != null) {
          state = state.copyWith(theme: savedTheme);
        }
      } else {
        state = state.copyWith(
          nodes: nodes,
          edges: edges,
          isLoading: false,
          camera: savedCamera ?? state.camera,
          theme: savedTheme ?? state.theme,
        );
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  // Interaction Methods
  void selectNode(String? nodeId) {
    // If selecting blank (null), also clear pin selection
    if (nodeId == null) {
      if (state.selectedPin != null) {
        state = state.copyWith(selectedPin: null);
      }
    }

    final nodes = [...state.nodes];
    bool changed = false;
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.isSelected != (node.id == nodeId)) {
        // Use copyWith for immutability
        nodes[i] = node.copyWith(isSelected: node.id == nodeId);

        // If unselecting, also exit edit mode
        if (!nodes[i].isSelected && node.isEditing) {
          nodes[i] = nodes[i].copyWith(isEditing: false);
          _saveNodeContent(nodes[i]); // Auto-save on exit edit
        }
        changed = true;
      }
    }
    if (changed) {
      state = state.copyWith(nodes: nodes);
    }

    // Update selectedNodeId in state
    if (state.selectedNodeId != nodeId) {
      state = state.copyWith(selectedNodeId: nodeId);
    }
  }

  void selectPin(String nodeId, String anchorId) {
    // Select the pin
    // Use position initialization or named args if constructor available
    // AnchorRef is Isar embedded object, so it has default constructor and fields are late.
    // We should initialize it like ..nodeId = ...
    final newPin = AnchorRef()
      ..nodeId = nodeId
      ..anchorId = anchorId;

    // If clicking same pin, toggle off? Or keep selected?
    // Requirement: "Click blank or other pin to switch/cancel".
    // Usually clicking same pin keeps it selected or does nothing.
    // Let's just set it.

    // Also select the node itself (recommended in requirements)
    selectNode(nodeId);

    state = state.copyWith(selectedPin: newPin);
  }

  void clearSelection() {
    selectNode(null);
    state = state.copyWith(selectedPin: null);
  }

  void enterEditMode(String nodeId) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      // Exit edit mode for others
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].id != nodeId) {
          if (nodes[i].isEditing) {
            nodes[i] = nodes[i].copyWith(isEditing: false);
            _saveNodeContent(nodes[i]);
          }
          if (nodes[i].isSelected) {
            nodes[i] = nodes[i].copyWith(isSelected: false);
          }
        }
      }

      nodes[index] = nodes[index].copyWith(isEditing: true, isSelected: true);
      state = state.copyWith(nodes: nodes);
    }
  }

  // Renamed to avoid conflict with updateNodeContent(id, content, tags)
  // This one is for simple content updates (e.g. from inline editor)
  void updateNodeContentOnly(String nodeId, String newContent) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(content: newContent);
      // We don't save to DB on every keystroke, only on exit edit or explicit save
      // But we update state to reflect in UI
      state = state.copyWith(nodes: nodes);
    }
  }

  void updateNodeBottomContentOnly(String nodeId, String newContent) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(bottomContent: newContent);
      state = state.copyWith(nodes: nodes);
    }
  }

  Future<void> _saveNodeContent(NodeEntity node) async {
    await _db.saveNode(node);
  }

  Future<void> exitEditMode(String nodeId) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(isEditing: false);
      await _db.saveNode(nodes[index]);
      state = state.copyWith(nodes: nodes);
    }
  }

  Future<void> _initializeDefaultBoard() async {
    // We NO LONGER create a default Totem here.
    // The UI will detect missing Totem and show the Initialization Overlay.

    // Just ensure state is updated with empty lists if needed
    if (state.nodes.isEmpty) {
      state = state.copyWith(nodes: [], edges: [], isLoading: false);
    }
  }

  Future<void> createTotem(String name, int styleIndex) async {
    final totemId = const Uuid().v4();
    // Center of 2080x1240 is (1040, 620)
    // Subtract half of totem size (200x200) to center it
    final totem = NodeEntity()
      ..id = totemId
      ..type = NodeType.totem
      ..content = name
      ..x = 1040 - 100
      ..y = 620 - 100
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..shape = CardShape.circle
      ..scale = 1.2
      ..isPinned = true
      ..styleIndex = styleIndex;

    final newNodes = [...state.nodes, totem];
    await _db.saveNode(totem);
    state = state.copyWith(nodes: newNodes);
  }

  Future<void> updateTotem(String nodeId, String name, int styleIndex) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(
        content: name,
        styleIndex: styleIndex,
      );
      await _db.saveNode(nodes[index]);
      state = state.copyWith(nodes: nodes);
    }
  }

  Future<void> updateNodePosition(String id, double x, double y) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(x: x, y: y);

      // Check for archive drop zone
      // Archive box is at bottom right of screen.
      // But node.x/y are in World Space.
      // We need to know if the node is "over" the archive button.
      // This logic is tricky inside controller without viewport context.
      // Ideally, the View (BoardScreen) should detect the drop and call archiveNode.
      // But we can check if y is very large? No, world is infinite.

      // We will rely on BoardScreen to pass a flag or call archiveNode directly if dropped on target.
      // For now, just save position.

      await _db.saveNode(nodes[index]);
      state = state.copyWith(nodes: nodes);
    }
  }

  Future<void> bringToFront(String id) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      int maxZ = 0;
      for (var n in nodes) {
        if (n.zIndex > maxZ) maxZ = n.zIndex;
      }
      nodes[index] = nodes[index].copyWith(zIndex: maxZ + 1);
      state = state.copyWith(nodes: nodes);
      _db.saveNode(nodes[index]);
    }
  }

  Future<NodeEntity> createNode(
    NodeType type,
    int styleIndex, {
    Offset? screenCenter, // Deprecated, kept for compatibility if needed
    Offset? worldCenter, // Preferred
  }) async {
    final id = const Uuid().v4();

    Offset center;
    if (worldCenter != null) {
      center = worldCenter;
    } else {
      // Default position (Camera Center)
      // Note: This logic might be flawed if padding is not accounted for in screenToWorld
      // But we are moving towards passing worldCenter from UI.
      final targetScreenPoint = screenCenter ?? const Offset(960, 540);
      center = state.camera.screenToWorld(targetScreenPoint);
    }

    // Apply random jitter
    final angle = Random().nextDouble() * 2 * pi;
    final radius = 100.0 + Random().nextDouble() * 100.0;

    // For theme cards, we might want less jitter or specific placement?
    // Current requirement seems fine with center + jitter.
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);

    final node = NodeEntity()
      ..id = id
      ..type = type
      ..x = x
      ..y = y
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..shape = CardShape.rectResizable
      ..styleIndex = styleIndex;

    // Special handling for Theme Card
    if (type == NodeType.theme) {
      final currentThemes =
          state.nodes.where((n) => n.type == NodeType.theme).toList();
      final newIndex = currentThemes.length + 1;
      final defaultTitle = "主题 #$newIndex";

      node.content = defaultTitle;
      node.themeId = defaultTitle;
      node.isPinned = true;
    } else {
      node.content = ""; // Empty content for new clue node
      node.isPinned = false;
    }

    // Connect edges if needed
    final newEdges = <EdgeEntity>[];
    if (type == NodeType.theme) {
      try {
        final totem = state.nodes.firstWhere((n) => n.type == NodeType.totem);
        final edge = EdgeEntity()
          ..id = const Uuid().v4()
          ..from = (AnchorRef()
            ..nodeId = totem.id
            ..anchorId = "main")
          ..to = (AnchorRef()
            ..nodeId = id
            ..anchorId = "main")
          ..createdAt = DateTime.now().millisecondsSinceEpoch
          ..style = "rope"; // Default style
        newEdges.add(edge);
      } catch (_) {
        // No totem found, ignore connection
      }
    }

    final command = AddNodeCommand(
      node: node,
      edges: newEdges,
      db: _db,
      onStateUpdate: (n, e) {
        state = state.copyWith(
          nodes: [...state.nodes, n],
          edges: [...state.edges, ...e],
        );
      },
    );

    await _commandProcessor.process(command);
    return node;
  }

  Future<void> addClueCard(String content, List<String> tags) async {
    final id = const Uuid().v4();

    double centerX = 1040.0;
    double centerY = 620.0;

    final themeNodes =
        state.nodes.where((n) => n.type == NodeType.theme).toList();

    // Strategy 1: Context-aware placement (Near linked themes)
    if (tags.isNotEmpty) {
      double sumX = 0;
      double sumY = 0;
      int count = 0;

      for (var tag in tags) {
        try {
          final themeNode = themeNodes.firstWhere((t) => t.themeId == tag);
          sumX += themeNode.x;
          sumY += themeNode.y;
          count++;
        } catch (_) {}
      }

      if (count > 0) {
        centerX = sumX / count;
        centerY = sumY / count;
      } else {
        // Fallback to camera center if no tags found in scene
        final center = state.camera.screenToWorld(
          const Offset(400, 300),
        ); // Approx
        centerX = center.dx;
        centerY = center.dy;
      }
    } else {
      // Strategy 2: Camera center placement
      // We assume a default viewport center if unknown, or use camera transform inverse
      // Since we don't know exact viewport size here, we estimate.
      // Or we can use the inverse of translation from the matrix
      // Matrix: [s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]
      // WorldX = (ScreenX - tx) / s

      // Let's assume screen center is roughly (WindowWidth/2, WindowHeight/2)
      // Hardcoded estimation for now (e.g. 1920x1080 / 2) -> 960, 540
      final center = state.camera.screenToWorld(const Offset(960, 540));
      centerX = center.dx;
      centerY = center.dy;
    }

    // Spiral/Jitter offset to avoid stacking
    // Simple random jitter for now, but spiral is better for density
    // Let's use a random angle and a random radius between 100-200
    final angle = Random().nextDouble() * 2 * pi;
    final radius = 100.0 + Random().nextDouble() * 100.0;

    final node = NodeEntity()
      ..id = id
      ..type = NodeType.clue
      ..content = content
      ..tags = tags
      ..x = centerX + radius * cos(angle)
      ..y = centerY + radius * sin(angle)
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..shape = CardShape.rectResizable
      ..isPinned = false
      ..styleIndex = Random().nextInt(8); // Random style 0-7 (now 8 styles)

    final newEdges = <EdgeEntity>[];

    for (var tag in tags) {
      try {
        final themeNode = themeNodes.firstWhere((t) => t.themeId == tag);
        final edge = EdgeEntity()
          ..id = const Uuid().v4()
          ..from = (AnchorRef()
            ..nodeId = id
            ..anchorId = "main")
          ..to = (AnchorRef()
            ..nodeId = themeNode.id
            ..anchorId = "main")
          ..createdAt = DateTime.now().millisecondsSinceEpoch
          ..style = "rope";
        newEdges.add(edge);
      } catch (e) {
        // Theme not found
      }
    }

    final command = AddNodeCommand(
      node: node,
      edges: newEdges,
      db: _db,
      onStateUpdate: (n, e) {
        state = state.copyWith(
          nodes: [...state.nodes, n],
          edges: [...state.edges, ...e],
        );
      },
    );

    await _commandProcessor.process(command);
  }

  void onCameraChanged(Matrix4 transform) {
    state = state.copyWith(camera: CameraState(transform));

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = transform.storage.map((e) => e.toString()).toList();
        await prefs.setStringList('camera_matrix', list);
      } catch (e) {
        debugPrint("Error saving camera: $e");
      }
    });
  }

  Future<void> archiveNode(String id) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final nodeToArchive = nodes[index];

      // Rule: Theme cards are not allowed to be archived
      if (nodeToArchive.type == NodeType.theme) {
        return;
      }

      // Snapshot theme content into tags
      List<String>? newTags;
      if (nodeToArchive.tags != null) {
        newTags = nodeToArchive.tags!.map((tag) {
          // Find the theme node on the board to get its current content
          final themeNode = nodes.firstWhere(
            (n) => n.themeId == tag && n.type == NodeType.theme,
            orElse: () => NodeEntity()..content = '', // Dummy
          );

          if (themeNode.content.isNotEmpty) {
            // Format: ThemeID|Content
            return "$tag|${themeNode.content}";
          }
          return tag;
        }).toList();
      }

      final archivedNode = nodeToArchive.copyWith(
        isArchived: true,
        archivedAt: DateTime.now().millisecondsSinceEpoch,
        tags: newTags ?? nodeToArchive.tags,
      );

      await _db.saveNode(archivedNode);

      // Remove all edges connected to this node
      final edges = [...state.edges];
      final edgesToRemove =
          edges.where((e) => e.from.nodeId == id || e.to.nodeId == id).toList();

      for (final edge in edgesToRemove) {
        await _db.deleteEdge(edge.id);
        edges.removeWhere((e) => e.id == edge.id);
      }

      nodes.removeAt(index);

      // Do NOT re-index themes when archiving a clue card.
      // This prevents theme cards from being reset or modified unnecessarily.
      state = state.copyWith(nodes: nodes, edges: edges);
    }
  }

  Future<List<NodeEntity>> _reindexThemesInternal(
    List<NodeEntity> currentNodes,
  ) async {
    final nodes = [...currentNodes];
    final themeNodes =
        nodes.where((n) => n.type == NodeType.theme && !n.isArchived).toList()
          ..sort((a, b) {
            // First try to sort by createdAt if available (not 0)
            if (a.createdAt != 0 &&
                b.createdAt != 0 &&
                a.createdAt != b.createdAt) {
              return a.createdAt.compareTo(b.createdAt);
            }

            // Fallback for legacy nodes: parse number from themeId or content
            int getNumber(NodeEntity n) {
              // Try themeId first as it's more stable
              final idMatch = RegExp(r'#(\d+)').firstMatch(n.themeId ?? '');
              if (idMatch != null) return int.tryParse(idMatch.group(1)!) ?? 0;

              // Try content
              final contentMatch = RegExp(r'#(\d+)').firstMatch(n.content);
              if (contentMatch != null) {
                return int.tryParse(contentMatch.group(1)!) ?? 0;
              }

              return 0;
            }

            final aNum = getNumber(a);
            final bNum = getNumber(b);
            if (aNum != bNum) return aNum.compareTo(bNum);

            // Ultimate fallback: use ID string comparison for stable sort
            return a.id.compareTo(b.id);
          });

    if (themeNodes.isEmpty) return nodes;

    final Map<String, String> themeIdMapping = {}; // Old -> New
    // More permissive pattern: allows spaces, newlines, and case-insensitive
    final defaultPattern = RegExp(r'^主题\s*#\s*\d+\s*$', multiLine: true);

    for (int i = 0; i < themeNodes.length; i++) {
      final node = themeNodes[i];
      final newIndex = i + 1;
      final newTitle = "主题 #$newIndex";
      final oldThemeId = node.themeId;

      final trimmedContent = node.content.trim();
      final bool isDefaultPattern =
          defaultPattern.hasMatch(trimmedContent) || trimmedContent.isEmpty;

      // Rule: If it's NOT a default pattern (user has edited it),
      // we NEVER overwrite the content, but we still update themeId for indexing.
      // We double check against empty string or purely whitespace just in case.
      final bool isActuallyDefault =
          isDefaultPattern && trimmedContent.isNotEmpty;
      final newContent = isActuallyDefault ? newTitle : node.content;

      if (node.content != newContent ||
          node.themeId != newTitle ||
          (isActuallyDefault &&
              node.textSpans != null &&
              node.textSpans!.isNotEmpty)) {
        final updatedNode = node.copyWith(
          content: newContent,
          themeId: newTitle,
          textSpans: isActuallyDefault ? [] : node.textSpans,
        );

        if (oldThemeId != null) {
          themeIdMapping[oldThemeId] = newTitle;
        }

        // Update in the local list
        final idxInFullList = nodes.indexWhere((n) => n.id == node.id);
        if (idxInFullList != -1) {
          nodes[idxInFullList] = updatedNode;
          await _db.saveNode(updatedNode);
        }
      }
    }

    // If any theme IDs changed, update clue cards that reference them
    if (themeIdMapping.isNotEmpty) {
      // 1. Update active nodes on the board
      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        if (node.type == NodeType.clue && node.tags != null) {
          bool clueChanged = false;
          final newTags = node.tags!.map((themeId) {
            if (themeIdMapping.containsKey(themeId)) {
              clueChanged = true;
              return themeIdMapping[themeId]!;
            }
            return themeId;
          }).toList();

          if (clueChanged) {
            nodes[i] = node.copyWith(tags: newTags);
            await _db.saveNode(nodes[i]);
          }
        }
      }

      // 2. Update archived clue nodes
      // We need to fetch them, update their tags, and save them back.
      final archivedClues = await _db.getArchivedClues();
      for (final clue in archivedClues) {
        if (clue.tags != null) {
          bool clueChanged = false;
          final newTags = clue.tags!.map((themeId) {
            if (themeIdMapping.containsKey(themeId)) {
              clueChanged = true;
              return themeIdMapping[themeId]!;
            }
            return themeId;
          }).toList();

          if (clueChanged) {
            final updatedClue = clue.copyWith(tags: newTags);
            await _db.saveNode(updatedClue);
          }
        }
      }
    }

    return nodes;
  }

  Future<void> updateNodeStyle(String id, int styleIndex) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(styleIndex: styleIndex);
      await _db.saveNode(nodes[index]);
      state = state.copyWith(nodes: nodes);
    }
  }

  Future<void> updateNodeTextStyle(String id, TextStyleSpec spec) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(textStyle: spec);
      // We need to update state immediately
      state = state.copyWith(nodes: nodes);
      await _db.saveNode(nodes[index]);
    }
  }

  Future<void> updateNodeTextSpans(String id, List<TextSpanSpec> spans) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(textSpans: spans);
      // Update state immediately
      state = state.copyWith(nodes: nodes);
      // Debounce saving if needed, but for now save immediately
      await _db.saveNode(nodes[index]);
    }
  }

  Future<void> updateNodeBottomTextSpans(
    String id,
    List<TextSpanSpec> spans,
  ) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(bottomTextSpans: spans);
      state = state.copyWith(nodes: nodes);
      await _db.saveNode(nodes[index]);
    }
  }

  void toggleStyleMode(String nodeId) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      final isMode = !nodes[index].isStyleMode;
      nodes[index] = nodes[index].copyWith(
        isStyleMode: isMode,
        composingTextStyle: isMode
            ? (nodes[index].composingTextStyle ?? nodes[index].textStyle)
            : nodes[index].textStyle,
      );
      state = state.copyWith(nodes: nodes);
    }
  }

  void updateNodeComposingTextStyle(String id, TextStyleSpec spec) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(composingTextStyle: spec);
      state = state.copyWith(nodes: nodes);
      // Transient state, do not save to DB
    }
  }

  Future<void> updateNodeContent(
    String id,
    String content,
    List<String> tags,
  ) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final oldNode = nodes[index];

      // If it's a theme node, we need to handle themeId and references
      if (oldNode.type == NodeType.theme) {
        // Find the current index/number of this theme
        final themeMatch = RegExp(r'#(\d+)').firstMatch(oldNode.themeId ?? '');
        final themeNum = themeMatch?.group(1) ?? '?';
        final newThemeId = "主题 #$themeNum";

        final updatedNode = oldNode.copyWith(
          content: content,
          themeId: newThemeId,
        );
        nodes[index] = updatedNode;
        await _db.saveNode(updatedNode);

        // Since content might have changed, and we want to "save" it in references,
        // we trigger a re-index which will handle all clue card tag updates.
        final updatedNodes = await _reindexThemesInternal(nodes);
        state = state.copyWith(nodes: updatedNodes);
      } else {
        nodes[index] = oldNode.copyWith(content: content, tags: tags);
        await _db.saveNode(nodes[index]);
        state = state.copyWith(nodes: nodes);
      }
    }
  }

  Future<void> deleteNode(String id) async {
    final index = state.nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final node = state.nodes[index];
      // For Theme cards, we do a hard delete (remove from board + DB)
      // because they don't go into the archive box.
      if (node.type == NodeType.theme) {
        // 1. Remove edges connected to this node
        final edges = [...state.edges];
        final edgesToRemove = edges
            .where((e) => e.from.nodeId == id || e.to.nodeId == id)
            .toList();

        for (final edge in edgesToRemove) {
          await _db.deleteEdge(edge.id);
          edges.removeWhere((e) => e.id == edge.id);
        }

        // 2. Delete node from DB
        await _db.deleteNode(id);

        // 3. Update State
        final nodes = [...state.nodes];
        nodes.removeAt(index);
        state = state.copyWith(nodes: nodes, edges: edges);
      } else {
        // For Clue cards, use existing archive logic
        await archiveNode(id);
      }
    }
  }

  Future<void> togglePin(String id) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      nodes[index] = nodes[index].copyWith(isPinned: !nodes[index].isPinned);
      await _db.saveNode(nodes[index]);
      state = state.copyWith(nodes: nodes);
    }
  }

  void switchTheme(String themeId) {
    ThemePack newTheme;
    switch (themeId) {
      case 'fresh':
        newTheme = ThemePack.fresh();
        break;
      case 'artistic':
        newTheme = ThemePack.artistic();
        break;
      case 'vintage':
      default:
        newTheme = ThemePack.vintage();
        break;
    }
    state = state.copyWith(theme: newTheme);

    // Persist theme choice
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('app_theme', themeId);
    });
  }

  Future<void> addConnection(
    String fromNodeId,
    String toNodeId, {
    String? fromAnchor,
    String? toAnchor,
  }) async {
    final sourceAnchor = fromAnchor ?? "main";
    final targetAnchor = toAnchor ?? "main";

    // Check if connection already exists
    final exists = state.edges.any(
      (e) =>
          (e.from.nodeId == fromNodeId &&
              e.from.anchorId == sourceAnchor &&
              e.to.nodeId == toNodeId &&
              e.to.anchorId == targetAnchor) ||
          (e.from.nodeId == toNodeId &&
              e.from.anchorId == targetAnchor &&
              e.to.nodeId == fromNodeId &&
              e.to.anchorId == sourceAnchor),
    );

    if (exists) return;

    // Create new edge
    final edge = EdgeEntity()
      ..id = const Uuid().v4()
      ..from = (AnchorRef()
        ..nodeId = fromNodeId
        ..anchorId = sourceAnchor)
      ..to = (AnchorRef()
        ..nodeId = toNodeId
        ..anchorId = targetAnchor)
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..style = "rope"; // Default style

    // Dispatch command
    // We can reuse AddNodeCommand but it requires a node.
    // Or we can just update state and DB directly for simplicity as we don't have AddEdgeCommand yet.
    // Actually, AddNodeCommand takes a list of edges. We can pass a dummy node? No.
    // Let's create a AddConnectionCommand or just do it here.
    // Since we want undo/redo later, commands are better. But for now, direct update.

    // Also need to update tags if one is Clue and other is Theme
    final nodes = [...state.nodes];
    final fromNode = nodes.firstWhere((n) => n.id == fromNodeId);
    final toNode = nodes.firstWhere((n) => n.id == toNodeId);

    if (fromNode.type == NodeType.clue && toNode.type == NodeType.theme) {
      // Add themeId to clue tags
      final currentTags = fromNode.tags ?? [];
      if (toNode.themeId != null && !currentTags.contains(toNode.themeId)) {
        fromNode.tags = [...currentTags, toNode.themeId!];
        await _db.saveNode(fromNode);
      }
    } else if (fromNode.type == NodeType.theme &&
        toNode.type == NodeType.clue) {
      final currentTags = toNode.tags ?? [];
      if (fromNode.themeId != null && !currentTags.contains(fromNode.themeId)) {
        toNode.tags = [...currentTags, fromNode.themeId!];
        await _db.saveNode(toNode);
      }
    }

    await _db.saveEdges([edge]);
    state = state.copyWith(edges: [...state.edges, edge], nodes: nodes);
  }

  Future<void> restoreNode(String id) async {
    final archivedNode = await _db.getArchivedNode(id);
    if (archivedNode != null) {
      // Clean tags by removing snapshot content (Format: ID|Content -> ID)
      List<String>? cleanTags;
      if (archivedNode.tags != null) {
        cleanTags =
            archivedNode.tags!.map((tag) => tag.split('|').first).toList();
      }

      final restoredNode = archivedNode.copyWith(
        isArchived: false,
        archivedAt: 0,
        tags: cleanTags ?? archivedNode.tags,
      );

      await _db.saveNode(restoredNode);

      // Refresh state
      final nodes = await _db.getAllNodes();
      state = state.copyWith(nodes: nodes);
    }
  }

  Future<List<NodeEntity>> getArchivedClues() async {
    return await _db.getArchivedClues();
  }

  Future<void> permanentDeleteNode(String id) async {
    await _db.deleteNode(id);
    // Refresh nodes from DB to trigger state update
    final nodes = await _db.getAllNodes();
    state = state.copyWith(nodes: nodes);
  }

  Future<List<NodeEntity>> getArchivedNodes() async {
    // This should be a DB query
    // But IsarService might not expose query by property easily without custom query
    // Let's assume we can fetch all and filter, or add method to DB service.
    // For now, let's fetch all nodes from DB and filter.
    final allNodes = await _db.getAllNodes();
    return allNodes.where((n) => n.isArchived).toList();
  }

  void expandBoard(double width, double height) {
    state = state.copyWith(boardWidth: width, boardHeight: height);
  }

  void toggleBoardResizing(bool isResizing) {
    state = state.copyWith(isResizing: isResizing);
  }

  Future<void> updateNodeSize(
    String id,
    double width,
    double height, {
    double? x,
    double? y,
    double? scale,
  }) async {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final node = nodes[index];
      // Create a NEW node object instead of mutating
      final newNode = node.copyWith(
        width: width,
        height: height,
        x: x ?? node.x,
        y: y ?? node.y,
        scale: scale ?? node.scale,
      );

      nodes[index] = newNode;

      // Update state IMMEDIATELY to prevent UI jitter
      state = state.copyWith(nodes: nodes);

      // Then save to DB
      await _db.saveNode(newNode);
    }
  }

  Future<void> resetBoard() async {
    state = state.copyWith(isLoading: true);
    await _db.clearAll();
    // Reset board dimensions to default (Fresh style: 2080x1240)
    // And clear nodes/edges to trigger empty state in _initializeDefaultBoard
    state = state.copyWith(
      boardWidth: 2080.0,
      boardHeight: 1240.0,
      nodes: [],
      edges: [],
    );
    await _initializeDefaultBoard();
  }

  void addImageBlock(String nodeId, ImageBlock block) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      final node = nodes[index];
      final newImages = [...node.images, block];
      nodes[index] = node.copyWith(images: newImages);
      state = state.copyWith(nodes: nodes);
    }
  }

  void updateImageBlock(String nodeId, ImageBlock newBlock) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      final node = nodes[index];
      final newImages = node.images.map((img) {
        return img.id == newBlock.id ? newBlock : img;
      }).toList();
      nodes[index] = node.copyWith(images: newImages);
      state = state.copyWith(nodes: nodes);
    }
  }

  void removeImageBlock(String nodeId, String blockId) {
    final nodes = [...state.nodes];
    final index = nodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      final node = nodes[index];
      final newImages = node.images.where((img) => img.id != blockId).toList();
      nodes[index] = node.copyWith(images: newImages);
      state = state.copyWith(nodes: nodes);
    }
  }
}
