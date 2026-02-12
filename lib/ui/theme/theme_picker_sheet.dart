import 'dart:ui';
import 'package:flutter/material.dart';

class ThemePickerSheet extends StatelessWidget {
  final String currentThemeId;
  final ValueChanged<String> onThemeSelected;

  const ThemePickerSheet({
    super.key,
    required this.currentThemeId,
    required this.onThemeSelected,
  });

  static const _themes = <_ThemeItem>[
    _ThemeItem(
      id: 'felt',
      name: '复古',
      asset: 'assets/images/bg_felt.png',
      accent: Color(0xFF8D6E63),
    ),
    _ThemeItem(
      id: 'fresh',
      name: '清新',
      asset: 'assets/images/bg_fresh.png',
      accent: Color(0xFFBCAAA4),
    ),
    _ThemeItem(
      id: 'artistic',
      name: '艺术',
      asset: 'assets/images/bg_artistic.png',
      accent: Color(0xFF90A4AE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Transparent modal sheet background is expected (backgroundColor: Colors.transparent)
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E6).withValues(alpha: 0.86),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle texture: reuse the currently selected background as a faint overlay.
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.10,
                      child: Image.asset(
                        _assetFor(currentThemeId),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),

                  // Vignette for depth (mimic Figma feel)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.35),
                            radius: 1.25,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top highlight strip (paper edge)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GrabHandle(),
                        const SizedBox(height: 10),
                        const Text(
                          '切换背景',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '选择侦探墙的氛围材质',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, c) {
                            // 3 items; make them distribute nicely on different widths
                            final itemWidth = (c.maxWidth - 12 * 2) / 3;
                            final tileSize = itemWidth.clamp(96.0, 128.0);

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _themes.map((t) {
                                final selected = t.id == currentThemeId;
                                return _ThemeTile(
                                  theme: t,
                                  selected: selected,
                                  size: tileSize,
                                  onTap: () => onThemeSelected(t.id),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _assetFor(String id) {
    final found = _themes.where((t) => t.id == id).toList();
    return found.isEmpty ? _themes.first.asset : found.first.asset;
  }
}

class _ThemeTile extends StatelessWidget {
  final _ThemeItem theme;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: const Color(0xFFB23A2B), width: 2.2)
        : Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.0);

    final labelColor = selected
        ? const Color(0xFFB23A2B)
        : Colors.black.withValues(alpha: 0.82);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              // Sample card: looks like a small "board sample" pinned on
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E6),
                  borderRadius: BorderRadius.circular(18),
                  border: border,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: selected ? 0.18 : 0.10),
                      blurRadius: selected ? 14 : 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    theme.asset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),

              // "Pin" dot (placeholder). If you later have a pin PNG, replace this.
              Positioned(
                left: 10,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected sticker
              if (selected)
                const Positioned(
                  right: 6,
                  top: 6,
                  child: _SelectedSticker(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            theme.name,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSticker extends StatelessWidget {
  const _SelectedSticker();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3C4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB23A2B), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.check, size: 16, color: Color(0xFFB23A2B)),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ThemeItem {
  final String id;
  final String name;
  final String asset;
  final Color accent;

  const _ThemeItem({
    required this.id,
    required this.name,
    required this.asset,
    required this.accent,
  });
}
