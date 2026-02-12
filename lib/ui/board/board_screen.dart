import 'dart:io'; // Platform check
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme/theme_pack.dart';
import 'board_controller.dart';
import 'layers/edges_layer.dart';
import 'utils/node_utils.dart';
import 'widgets/node_widget.dart';
import '../../scene/models/node_entity.dart';
import '../create/create_type_sheet.dart';
import '../style/style_gallery_sheet.dart';
import '../theme/theme_picker_sheet.dart';
import '../widgets/detective_wall_background.dart';
import '../archive/archive_box_sheet.dart';
import 'widgets/text_style_toolbar.dart'; // Import toolbar
import 'widgets/board_resize_handle.dart'; // Import
import 'widgets/totem_initialization_overlay.dart'; // Import Totem Overlay

import 'board_exporter.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  final TransformationController _transformController =
      TransformationController();

  final GlobalKey _archiveFabKey = GlobalKey();
  final GlobalKey _boardViewRepaintKey = GlobalKey();
  bool _isHoveringArchive = false;

  // Pin drag state
  bool _isDraggingPin = false;
  String? _dragStartNodeId;
  Offset? _dragStartPosition; // World space
  Offset? _dragCurrentPosition; // World space

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onCameraChange);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onCameraChange);
    _transformController.dispose();
    super.dispose();
  }

  void _onCameraChange() {
    // Sync camera state to Riverpod (e.g. for HUD or logic)
    ref
        .read(boardControllerProvider.notifier)
        .onCameraChanged(_transformController.value);
  }

  Future<void> _pickImage() async {
    final controller = ref.read(boardControllerProvider.notifier);
    final boardState = ref.read(boardControllerProvider);
    final activeNode = boardState.nodes.cast<NodeEntity?>().firstWhere(
          (n) => n != null && n.isSelected,
          orElse: () => null,
        );
    if (activeNode == null) return;

    Uint8List? bytes;

    try {
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // Desktop: FilePicker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.single;
          bytes = file.bytes;
          if (bytes == null && file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
        }
      } else {
        // Mobile: ImagePicker
        final picker = ImagePicker();
        final xfile = await picker.pickImage(source: ImageSource.gallery);
        if (xfile != null) {
          bytes = await xfile.readAsBytes();
        }
      }

      if (bytes != null) {
        _insertImageBlock(controller, activeNode.id, bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _insertImageBlock(
    BoardController controller,
    String nodeId,
    Uint8List bytes,
  ) {
    // Determine size (simple logic for now)
    // w = min(cardInnerWidth * 0.75, 320)
    // h = w * 0.60
    const w = 200.0;
    const h = 120.0;

    final block = ImageBlock(
      id: const Uuid().v4(),
      bytes: bytes,
      width: w,
      height: h,
    );

    controller.addImageBlock(nodeId, block);
  }

  void _deleteImageBlock(String nodeId, String imageId) {
    ref
        .read(boardControllerProvider.notifier)
        .removeImageBlock(nodeId, imageId);
  }

  void _updateImageBlock(String nodeId, ImageBlock block) {
    ref.read(boardControllerProvider.notifier).updateImageBlock(nodeId, block);
  }

  void _checkDragOverlap(double worldX, double worldY) {
    final RenderBox? fabBox =
        _archiveFabKey.currentContext?.findRenderObject() as RenderBox?;
    if (fabBox == null) return;

    // Get FAB bounds in global screen coordinates
    final fabPosition = fabBox.localToGlobal(Offset.zero);
    final fabRect = fabPosition & fabBox.size;

    // Convert World Coordinates (x, y) to Screen Coordinates
    // Using matrix: Screen = Transform * World
    final matrix = _transformController.value;
    final screenPoint = MatrixUtils.transformPoint(
      matrix,
      Offset(worldX + AppConstants.kBoardPadding,
          worldY + AppConstants.kBoardPadding),
    );

    // Check intersection
    // We add an offset to center the "drop point" of the node (node center)
    // Assuming x,y is top-left of node? No, usually center or top-left.
    // DraggableNode state x,y is top-left of Positioned.
    // Let's assume node size approx 100x100, so add 50,50 to get center.
    final dropPoint = screenPoint + const Offset(50, 50);

    final isOver = fabRect.contains(dropPoint);

    if (isOver != _isHoveringArchive) {
      if (isOver) {
        HapticFeedback.lightImpact();
      }
      setState(() {
        _isHoveringArchive = isOver;
      });
    }
  }

  void _onPinDragStart(String nodeId, Offset nodePosition) {
    // Select the pin immediately when drag starts
    ref.read(boardControllerProvider.notifier).selectPin(nodeId, "main");

    // Calculate exact anchor position to avoid "floating" line during initial drag
    final boardState = ref.read(boardControllerProvider);
    final node = boardState.nodes.firstWhere((n) => n.id == nodeId);
    final anchorPos = _getPinWorldPosition(node, boardState.theme);

    setState(() {
      _isDraggingPin = true;
      _dragStartNodeId = nodeId;
      _dragStartPosition = anchorPos;
    });
  }

  void _onPinDragUpdate(Offset globalPosition) {
    // Convert screen to world
    final worldPos = _screenToWorld(globalPosition);

    setState(() {
      _dragStartPosition ??= worldPos;
      _dragCurrentPosition = worldPos;
    });
  }

  void _onPinDragEnd(BoardController controller) {
    if (_dragStartNodeId != null && _dragCurrentPosition != null) {
      final boardState = ref.read(boardControllerProvider);
      final nodes = boardState.nodes;
      final messenger = ScaffoldMessenger.of(context);
      for (final node in nodes) {
        if (node.isArchived) continue;
        if (node.id == _dragStartNodeId) continue;
        if (node.type != NodeType.theme && node.type != NodeType.clue) continue;

        final pinCenter = _getPinWorldPosition(node, boardState.theme);
        final radius = node.type == NodeType.theme ? 22.0 : 20.0;
        if ((pinCenter - _dragCurrentPosition!).distance > radius) continue;

        final startId = _dragStartNodeId!;
        final targetId = node.id;
        controller.addConnection(startId, targetId).then((_) {
          final label = node.type == NodeType.theme
              ? node.content
              : (node.content.trim().isNotEmpty ? node.content : '线索卡');
          messenger.showSnackBar(
            SnackBar(content: Text('已连接到 $label')),
          );
        });
        break;
      }
    }

    setState(() {
      _isDraggingPin = false;
      _dragStartNodeId = null;
      _dragStartPosition = null;
      _dragCurrentPosition = null;
    });
  }

  Offset _getPinWorldPosition(NodeEntity node, ThemePack theme) {
    final size = NodeUtils.getNodeSize(node, theme);
    final width = size.width * node.scale;
    final height = size.height * node.scale;

    double pinOffsetY = 25.0;
    if (node.type == NodeType.theme) {
      pinOffsetY = 30.0;
    } else if (node.type == NodeType.totem) {
      pinOffsetY = node.styleIndex % 4 == 0 ? 25.0 : 75.0;
    } else if (node.type == NodeType.clue) {
      final assets = theme.clueCardAssets;
      if (assets.isNotEmpty) {
        final index = node.styleIndex % assets.length;
        final safeIndex = index < 0 ? 0 : index;
        final assetPath = assets[safeIndex];
        if (assetPath.contains('light')) {
          const alignmentY = -0.6;
          const pinMarginTop = 5.0;
          const pinHitSize = 40.0;
          const childHeight = pinMarginTop + pinHitSize;
          final available = height - childHeight;
          if (available > 0) {
            final offsetY = ((alignmentY + 1) / 2) * available;
            pinOffsetY = offsetY + pinMarginTop + pinHitSize / 2;
          }
        }
      }
    }

    return Offset(node.x + width / 2, node.y + pinOffsetY);
  }

  Offset _screenToWorld(Offset screenPoint) {
    final matrix = _transformController.value;
    final point = MatrixUtils.transformPoint(
      Matrix4.inverted(matrix),
      screenPoint,
    );
    return point -
        const Offset(AppConstants.kBoardPadding, AppConstants.kBoardPadding);
  }

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardControllerProvider);
    final controller = ref.read(boardControllerProvider.notifier);

    // Listen to camera changes from logic (e.g. Reset)
    ref.listen(boardControllerProvider.select((s) => s.camera), (prev, next) {
      if (next.transform != _transformController.value) {
        _transformController.value = next.transform;
      }
    });

    // Find selected node by isSelected property (since boardState.selectedNodeId might not be sync'd perfectly or just redundant)
    // Actually controller uses isSelected flag.
    // Let's find the single selected node.
    final activeNode = boardState.nodes.cast<NodeEntity?>().firstWhere(
          (n) => n != null && n.isSelected,
          orElse: () => null,
        );

    final showStyleControls = activeNode != null && activeNode.isEditing;
    final showToolbar = showStyleControls && activeNode.isStyleMode;

    // Check for Totem
    final hasTotem = boardState.nodes.any((n) => n.type == NodeType.totem);

    if (boardState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: RepaintBoundary(
        key: _boardViewRepaintKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(2000),
              minScale: 0.1,
              maxScale: 2.5,
              constrained: false,
              child: GestureDetector(
                onTap: () {
                  controller.selectNode(null);
                  if (boardState.isResizing) {
                    controller.toggleBoardResizing(false);
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: boardState.boardWidth + AppConstants.kBoardPadding * 2,
                  height:
                      boardState.boardHeight + AppConstants.kBoardPadding * 2,
                  color: Colors.transparent,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: AppConstants.kBoardPadding,
                        top: AppConstants.kBoardPadding,
                        width: boardState.boardWidth,
                        height: boardState.boardHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: boardState.boardWidth,
                              height: boardState.boardHeight,
                              color: const Color(0xFFF7F3EF),
                              child: boardState.theme.backgroundTexture != null
                                  ? DetectiveWallBackground(
                                      boardState.theme.backgroundTexture!,
                                    )
                                  : null,
                            ),
                            Positioned.fill(
                              child: BoardResizeHandle(
                                width: boardState.boardWidth,
                                height: boardState.boardHeight,
                                isResizing: boardState.isResizing,
                                onResize: (w, h) {
                                  controller.expandBoard(w, h);
                                },
                                onResizeEnd: () {},
                                onDoubleTapEdge: () {
                                  controller.toggleBoardResizing(
                                    !boardState.isResizing,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: AppConstants.kBoardPadding,
                        top: AppConstants.kBoardPadding,
                        child: EdgesLayer(
                          nodes: boardState.nodes,
                          edges: boardState.edges,
                          theme: boardState.theme,
                        ),
                      ),
                      if (_isDraggingPin &&
                          _dragStartPosition != null &&
                          _dragCurrentPosition != null)
                        Positioned(
                          left: AppConstants.kBoardPadding,
                          top: AppConstants.kBoardPadding,
                          child: CustomPaint(
                            painter: _DragLinePainter(
                              start: _dragStartPosition!,
                              end: _dragCurrentPosition!,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      for (final node
                          in (boardState.nodes.toList()
                            ..sort((a, b) => a.zIndex.compareTo(b.zIndex))))
                        Positioned(
                          left: AppConstants.kBoardPadding + node.x,
                          top: AppConstants.kBoardPadding + node.y,
                          child: DraggableNode(
                            key: ValueKey(node.id),
                            node: node,
                            theme: boardState.theme,
                            screenToWorld: _screenToWorld,
                            isPinSelected:
                                boardState.selectedPin?.nodeId == node.id,
                            onPinTap: () {
                              controller.selectPin(node.id, "main");
                            },
                            onTap: () {
                              final wasSelected = node.isSelected;
                              controller.selectNode(node.id);
                              if (node.type == NodeType.theme && wasSelected) {
                                _showStylePickerForExistingNode(
                                  context,
                                  controller,
                                  node,
                                );
                              } else if (node.type == NodeType.totem) {
                                _showTotemEditOverlay(
                                  context,
                                  controller,
                                  node,
                                );
                              }
                            },
                            onDoubleTap: () {
                              controller.enterEditMode(node.id);
                            },
                            onContentChanged: (content) {
                              controller.updateNodeContentOnly(
                                node.id,
                                content,
                              );
                            },
                            onBottomContentChanged: (content) {
                              controller.updateNodeBottomContentOnly(
                                node.id,
                                content,
                              );
                            },
                            onSpansChanged: (spans) {
                              controller.updateNodeTextSpans(node.id, spans);
                            },
                            onBottomSpansChanged: (spans) {
                              controller.updateNodeBottomTextSpans(
                                node.id,
                                spans,
                              );
                            },
                            onEditExit: () {
                              controller.exitEditMode(node.id);
                            },
                            onDragUpdate: (x, y) {
                              if (node.type != NodeType.theme) {
                                _checkDragOverlap(x, y);
                              }
                            },
                            onDragEnd: (newX, newY) {
                              if (node.type != NodeType.theme &&
                                  _isHoveringArchive) {
                                controller.archiveNode(node.id);
                                setState(() {
                                  _isHoveringArchive = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已归档')),
                                );
                              } else {
                                controller.updateNodePosition(
                                  node.id,
                                  newX,
                                  newY,
                                );
                                if (_isHoveringArchive) {
                                  setState(() {
                                    _isHoveringArchive = false;
                                  });
                                }
                              }
                            },
                            onDelete: () {
                              controller.deleteNode(node.id);
                            },
                            onDeleteImage: (imgId) {
                              _deleteImageBlock(node.id, imgId);
                            },
                            onUpdateImage: (block) {
                              _updateImageBlock(node.id, block);
                            },
                            onPinDragStart: (global) {
                              _onPinDragStart(
                                node.id,
                                _screenToWorld(global),
                              );
                            },
                            onPinDragUpdate: (local, global) {
                              _onPinDragUpdate(global);
                            },
                            onPinDragEnd: (global) {
                              _onPinDragEnd(controller);
                            },
                            onScaleEnd: (scale, x, y) {
                              final size = NodeUtils.getNodeSize(
                                node,
                                boardState.theme,
                              );
                              controller.updateNodeSize(
                                node.id,
                                size.width,
                                size.height,
                                scale: scale,
                                x: x,
                                y: y,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: hasTotem || boardState.isLoading,
              child: TotemInitializationOverlay(
                theme: boardState.theme,
                onCreate: (name, styleIndex) {
                  controller.createTotem(name, styleIndex);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showToolbar)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, right: 0),
              child: TextStyleToolbar(
                node: activeNode,
                theme: boardState.theme,
                onStyleChanged: (spec) {
                  controller.updateNodeComposingTextStyle(activeNode.id, spec);
                },
                onInsertImage: _pickImage,
              ),
            ),
          if (showStyleControls)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                heroTag: "style_mode_toggle",
                mini: true,
                backgroundColor:
                    activeNode.isStyleMode ? Colors.black87 : Colors.white,
                foregroundColor:
                    activeNode.isStyleMode ? Colors.white : Colors.black87,
                onPressed: () {
                  controller.toggleStyleMode(activeNode.id);
                },
                child: const Text(
                  "T",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          FloatingActionButton(
            heroTag: "reset_board",
            mini: true,
            backgroundColor: Colors.red[50],
            elevation: 1,
            onPressed: () {
              _showResetDialog(context, controller);
            },
            tooltip: 'Reset Board',
            child: const Icon(Icons.delete_forever, color: Colors.red),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "export_board",
            mini: true,
            backgroundColor: Colors.blue[50],
            elevation: 1,
            onPressed: () {
              BoardExporter.exportBoard(
                context: context,
                repaintBoundaryKey: _boardViewRepaintKey,
              );
            },
            tooltip: 'Export Board',
            child: const Icon(Icons.download, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "reset_camera",
            onPressed: () {
              _resetCamera(context, controller);
            },
            child: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            key: _archiveFabKey,
            heroTag: "archive_box",
            backgroundColor: _isHoveringArchive ? Colors.red.shade100 : null,
            onPressed: () {
              _showArchiveBox(context, controller);
            },
            child: Icon(
              _isHoveringArchive ? Icons.archive : Icons.inventory_2_outlined,
              color: _isHoveringArchive ? Colors.red : null,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "theme_switch",
            onPressed: () {
              _showThemePicker(context, controller, boardState.theme);
            },
            child: const Icon(Icons.palette),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "add_entry",
            onPressed: () {
              _showCreateTypeSheet(context, controller);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, BoardController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Board?'),
        content: const Text(
          'This will delete all data and reset to default. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.resetBoard();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetCamera(BuildContext context, BoardController controller) {
    final boardState = ref.read(boardControllerProvider);
    const scale = 0.45;
    final matrix = Matrix4.diagonal3Values(scale, scale, scale);
    final bx = boardState.boardWidth / 2.0;
    final by = boardState.boardHeight / 2.0;
    final size = MediaQuery.of(context).size;
    final vx = size.width / 2;
    final vy = size.height / 2;
    final tx = vx - (bx + AppConstants.kBoardPadding) * scale;
    final ty = vy - (by + AppConstants.kBoardPadding) * scale;
    matrix.setTranslationRaw(tx, ty, 0);
    controller.onCameraChanged(matrix);
  }

  void _showTotemEditOverlay(
    BuildContext context,
    BoardController controller,
    NodeEntity totemNode,
  ) {
    final theme = ref.read(boardControllerProvider).theme;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => TotemInitializationOverlay(
        theme: theme,
        initialName: totemNode.content,
        initialStyleIndex: totemNode.styleIndex,
        isEditing: true,
        onDismiss: () => Navigator.pop(ctx),
        onCreate: (name, styleIndex) {
          controller.updateTotem(totemNode.id, name, styleIndex);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    BoardController controller,
    ThemePack currentTheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThemePickerSheet(
        currentThemeId: currentTheme.id,
        onThemeSelected: (themeId) {
          controller.switchTheme(themeId);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCreateTypeSheet(BuildContext context, BoardController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTypeSheet(
        onTypeSelected: (type) {
          Navigator.pop(context);
          _handleCreateType(type, controller);
        },
      ),
    );
  }

  void _handleCreateType(NodeType type, BoardController controller) {
    switch (type) {
      case NodeType.theme:
        _startStyledCreate(context, controller, NodeType.theme);
        break;
      case NodeType.totem:
        break;
      case NodeType.clue:
        _startStyledCreate(context, controller, NodeType.clue);
        break;
    }
  }

  void _startStyledCreate(
    BuildContext context,
    BoardController controller,
    NodeType type,
  ) {
    _showStylePickerForCreation(context, controller, type);
  }

  void _showStylePickerForCreation(
    BuildContext context,
    BoardController controller,
    NodeType type,
  ) {
    final tempNode = NodeEntity()
      ..id = "temp_creation_node"
      ..type = type
      ..styleIndex = 0;

    final theme = ref.read(boardControllerProvider).theme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StyleGallerySheet(
        theme: theme,
        node: tempNode,
        onStyleSelected: (index) {
          Navigator.pop(ctx);
          // Create node with selected style
          _createNodeAndOpenEditor(context, controller, type, index);
        },
      ),
    );
  }

  void _showStylePickerForExistingNode(
    BuildContext context,
    BoardController controller,
    NodeEntity node,
  ) {
    final theme = ref.read(boardControllerProvider).theme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StyleGallerySheet(
        theme: theme,
        node: node,
        onStyleSelected: (index) {
          Navigator.pop(ctx);
          controller.updateNodeStyle(node.id, index);
        },
      ),
    );
  }

  void _createNodeAndOpenEditor(
    BuildContext context,
    BoardController controller,
    NodeType type,
    int styleIndex,
  ) {
    // We need to add the node to the board first.
    // We can use a modified addClueCard that takes styleIndex and returns the ID.
    // But addClueCard is async and doesn't return ID currently.
    // Let's modify BoardController to support this flow better.

    // For now, let's use the existing addClueCard but we need to pass style.
    // The current addClueCard generates random style. We should update it.

    // Workaround:
    // We will implement a new method in controller: createNode(type, styleIndex) -> Future<String>
    // Then open editor.

    // Calculate viewport center
    final size = MediaQuery.of(context).size;
    final screenCenter = Offset(size.width / 2, size.height / 2);
    final worldCenter = _screenToWorld(screenCenter);

    if (type == NodeType.theme) {
      controller
          .createNode(type, styleIndex, worldCenter: worldCenter)
          .then((node) {
        if (!context.mounted) return;
        // Theme card also enters inline edit now
        controller.enterEditMode(node.id);
      }).catchError((e) {
        debugPrint("Error creating theme node: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      });
    } else {
      controller
          .createNode(type, styleIndex, worldCenter: worldCenter)
          .then((node) {
        if (!context.mounted) return;
        // Skip editor sheet, enter inline edit directly
        controller.enterEditMode(node.id);
      }).catchError((e) {
        debugPrint("Error creating node: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      });
    }
  }

  void _showArchiveBox(BuildContext context, BoardController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ArchiveBoxSheet(
        onRestore: (nodeId) {
          controller.restoreNode(nodeId);
        },
        onDelete: (nodeId) {
          controller.permanentDeleteNode(nodeId);
        },
      ),
    );
  }
}

class _DragLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _DragLinePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rope Style Paint
    final paint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Shadow Paint
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Quadratic bezier for slack
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final dist = (start - end).distance;
    final slack = dist * 0.15; // Same slack factor as EdgesLayer

    path.quadraticBezierTo(midX, midY + slack, end.dx, end.dy);

    // Draw shadow then rope
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DragLinePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}
