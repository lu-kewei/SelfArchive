import 'package:flutter/material.dart';
import '../../../scene/models/node_entity.dart';
import '../../../core/theme/theme_pack.dart';

enum Corner { tl, tr, bl, br }

class NodeUtils {
  static Size getNodeSize(NodeEntity node, ThemePack theme) {
    // Default dimensions (Increased from 160x100)
    double baseWidth = 240;
    double baseHeight = 150;

    if (node.type == NodeType.totem) {
      baseWidth = 200; // Increased from 120
      baseHeight = 200;
    } else if (node.type == NodeType.clue) {
      if (theme.clueCardAssets.isNotEmpty) {
        // Safe index access
        final index = node.styleIndex % theme.clueCardAssets.length;
        final safeIndex = index < 0 ? 0 : index;
        final assetPath = theme.clueCardAssets[safeIndex];

        // Determine dimensions based on specific asset
        // Multiplied previous sizes by approx 1.5x
        if (assetPath.contains('hanging_tag')) {
          baseWidth = 300; // was 200
          baseHeight = 354; // was 236
        } else if (assetPath.contains('taped_note')) {
          baseWidth = 225; // was 150
          baseHeight = 315; // was 210
        } else if (assetPath.contains('target_frame')) {
          baseWidth = 300; // was 200
          baseHeight = 120; // was 80
        } else if (assetPath.contains('frame_lilyofthevalley') ||
            assetPath.contains('frame_sakura')) {
          baseWidth = 255; // was 170
          baseHeight = 255;
        } else if (assetPath.contains('framed_sheet')) {
          baseWidth = 240; // was 160
          baseHeight = 180; // was 120
        } else if (assetPath.contains('onepiece')) {
          baseWidth = 260;
          baseHeight = 360;
        } else if (assetPath.contains('light')) {
          baseWidth = 420;
          baseHeight = 280;
        } else {
          // Fallback for floral frames or others
          baseWidth = 240; // was 160
          baseHeight = 240;
        }
      } else {
        baseWidth = 240;
        baseHeight = 150;
      }
    } else if (node.type == NodeType.theme) {
      // Theme nodes (usually sticky notes or simple frames)
      // Default was implicit 160x100
      baseWidth = 240;
      baseHeight = 150;
    }

    // Apply node specific overrides if any (though usually null for now)
    baseWidth = node.width ?? baseWidth;
    baseHeight = node.height ?? baseHeight;

    return Size(baseWidth, baseHeight);
  }
}
