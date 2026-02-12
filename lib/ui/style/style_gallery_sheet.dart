import 'package:flutter/material.dart';
import '../../core/theme/theme_pack.dart';
import '../../scene/models/node_entity.dart';

class StyleGallerySheet extends StatefulWidget {
  final ThemePack theme;
  final NodeEntity node;
  final Function(int) onStyleSelected;

  const StyleGallerySheet({
    super.key,
    required this.theme,
    required this.node,
    required this.onStyleSelected,
  });

  @override
  State<StyleGallerySheet> createState() => _StyleGallerySheetState();
}

class _StyleGallerySheetState extends State<StyleGallerySheet> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.node.styleIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> assets = widget.node.type == NodeType.theme
        ? widget.theme.themeFrameAssets
        : (widget.node.type == NodeType.clue
            ? widget.theme.clueCardAssets
            : []);

    if (assets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      // Use SafeArea + constrained height
      height: 300, // Increase height to accommodate content
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择样式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 4), // Add horizontal padding for shadow/border
                itemCount: assets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 20), // Increase spacing
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      if (_selectedIndex == index) {
                        widget.onStyleSelected(index);
                      } else {
                        setState(() {
                          _selectedIndex = index;
                        });
                      }
                    },
                    child: Container(
                      width: 140, // Increase width for better visibility
                      decoration: BoxDecoration(
                        color: Colors.white, // Ensure background is white
                        border: isSelected
                            ? Border.all(
                                color: widget.theme.accentColor, width: 3)
                            : Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(
                                  8.0), // Add padding inside frame
                              child: Image.asset(assets[index],
                                  fit: BoxFit
                                      .contain), // Use contain to see full asset
                            ),
                            if (isSelected)
                              Container(
                                color: widget.theme.accentColor
                                    .withValues(alpha: 0.2),
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: widget.theme.accentColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
