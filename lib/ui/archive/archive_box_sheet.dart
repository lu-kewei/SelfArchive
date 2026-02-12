import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../scene/models/node_entity.dart';
import '../../core/theme/theme_pack.dart';
import '../board/board_controller.dart';
import '../board/widgets/card_widget.dart';

class ArchiveBoxSheet extends ConsumerWidget {
  final Function(String) onRestore;
  final Function(String) onDelete;

  const ArchiveBoxSheet({
    super.key,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardControllerProvider);
    final controller = ref.read(boardControllerProvider.notifier);
    final theme = boardState.theme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, theme),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<NodeEntity>>(
              future: controller.getArchivedClues(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final archivedClues = snapshot.data ?? [];
                if (archivedClues.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: archivedClues.length,
                  itemBuilder: (context, index) {
                    final node = archivedClues[index];
                    return _buildArchiveEntry(context, ref, node, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemePack theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: theme.accentColor),
              const SizedBox(width: 12),
              Text(
                '档案盒',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemePack theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined,
              size: 64, color: theme.accentColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '暂无归档线索',
            style: TextStyle(
                color: theme.accentColor.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveEntry(
      BuildContext context, WidgetRef ref, NodeEntity node, ThemePack theme) {
    final archivedAt = DateTime.fromMillisecondsSinceEpoch(node.archivedAt);
    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(archivedAt);
    final boardState = ref.read(boardControllerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thumbnail
          _buildThumbnail(node, theme),
          const SizedBox(width: 16),
          // 2. Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.content.isNotEmpty ? node.content : '未命名线索',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '归档于: $timeStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                // 3. Theme Tags
                _buildThemeTags(node, boardState, theme),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => _confirmDelete(context, node),
                tooltip: '永久删除',
              ),
              IconButton(
                icon: Icon(Icons.unarchive_outlined, color: theme.accentColor),
                onPressed: () => onRestore(node.id),
                tooltip: '恢复到画布',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, NodeEntity node) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
            '确定要永久删除线索 "${node.content.isNotEmpty ? node.content : '未命名线索'}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onDelete(node.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(NodeEntity node, ThemePack theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: OverflowBox(
          maxWidth: 240,
          maxHeight: 240,
          child: Transform.scale(
            scale: 80 / 240,
            child: IgnorePointer(
              child: CardWidget(
                node: node,
                scale: 1.0,
                theme: theme,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTags(NodeEntity node, dynamic boardState, ThemePack theme) {
    if (node.tags == null || node.tags!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Map themeId to content
    final tags = node.tags!.map((tagString) {
      // Check if tag has snapshot content (Format: ID|Content)
      final parts = tagString.split('|');
      final themeId = parts.first;
      final snapshotContent =
          parts.length > 1 ? parts.sublist(1).join('|') : null;

      // Find the theme node in the current board state (Live Data)
      final themeNode = boardState.nodes.cast<NodeEntity?>().firstWhere(
            (n) => n?.type == NodeType.theme && n?.themeId == themeId,
            orElse: () => null,
          );

      // Helper to just return content (Simplified logic: Show exactly what is in the content)
      String getDisplayText(String id, String content) {
        if (content.trim().isNotEmpty) {
          return content.trim();
        }
        return id;
      }

      // Priority 1: Use snapshot content if available
      if (snapshotContent != null && snapshotContent.isNotEmpty) {
        return getDisplayText(themeId, snapshotContent);
      }

      // Priority 2: Live board data (Fallback)
      if (themeNode != null) {
        return getDisplayText(themeNode.themeId ?? themeId, themeNode.content);
      }

      return themeId;
    }).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12, // Increased slightly for readability
                    color: theme.accentColor.withValues(alpha: 1.0),
                    fontWeight: FontWeight
                        .w600, // Slightly bolder for better visibility
                    height: 1.2, // Fix line height
                  ),
                ),
              ))
          .toList(),
    );
  }
}
