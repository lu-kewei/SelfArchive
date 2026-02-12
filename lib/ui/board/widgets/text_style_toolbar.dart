import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../scene/models/node_entity.dart';
import '../../../core/theme/theme_pack.dart';

class TextStyleToolbar extends StatelessWidget {
  final NodeEntity node;
  final ThemePack theme;
  final Function(TextStyleSpec) onStyleChanged;
  final VoidCallback? onInsertImage;

  const TextStyleToolbar({
    super.key,
    required this.node,
    required this.theme,
    required this.onStyleChanged,
    this.onInsertImage,
  });

  @override
  Widget build(BuildContext context) {
    // Use composing style if available (active editing), otherwise default style
    final spec = node.composingTextStyle ?? node.textStyle;

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fonts
          _FontButton(
            label: 'R', // Rational
            isSelected: spec.font == TextFontPreset.rational,
            fontStyle: GoogleFonts.notoSansSc(),
            onTap: () =>
                _updateStyle(spec.copyWith(font: TextFontPreset.rational)),
          ),
          _FontButton(
            label: 'V', // Vintage
            isSelected: spec.font == TextFontPreset.vintage,
            fontStyle: GoogleFonts.zcoolXiaoWei(),
            onTap: () =>
                _updateStyle(spec.copyWith(font: TextFontPreset.vintage)),
          ),
          _FontButton(
            label: 'H', // Handwriting
            isSelected: spec.font == TextFontPreset.handwriting,
            fontStyle: GoogleFonts.maShanZheng(),
            onTap: () =>
                _updateStyle(spec.copyWith(font: TextFontPreset.handwriting)),
          ),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // Size
          _SizeButton(
            label: 'S',
            isSelected: spec.size == TextSizePreset.small,
            onTap: () =>
                _updateStyle(spec.copyWith(size: TextSizePreset.small)),
          ),
          _SizeButton(
            label: 'M',
            isSelected: spec.size == TextSizePreset.medium,
            onTap: () =>
                _updateStyle(spec.copyWith(size: TextSizePreset.medium)),
          ),
          _SizeButton(
            label: 'L',
            isSelected: spec.size == TextSizePreset.large,
            onTap: () =>
                _updateStyle(spec.copyWith(size: TextSizePreset.large)),
          ),

          const VerticalDivider(width: 16, indent: 8, endIndent: 8),

          // Style
          _StyleIconButton(
            icon: Icons.format_bold,
            isActive: spec.bold,
            onTap: () => _updateStyle(spec.copyWith(bold: !spec.bold)),
          ),
          _StyleIconButton(
            icon: Icons.format_italic,
            isActive: spec.italic,
            onTap: () => _updateStyle(spec.copyWith(italic: !spec.italic)),
          ),
          _StyleIconButton(
            icon: Icons.format_underline,
            isActive: spec.underline,
            onTap: () =>
                _updateStyle(spec.copyWith(underline: !spec.underline)),
          ),
          _StyleIconButton(
            icon: Icons.format_paint, // Highlight
            isActive: spec.highlight,
            onTap: () =>
                _updateStyle(spec.copyWith(highlight: !spec.highlight)),
          ),

          if (onInsertImage != null) ...[
            const VerticalDivider(width: 16, indent: 8, endIndent: 8),
            _StyleIconButton(
              icon: Icons.image,
              isActive: false,
              onTap: onInsertImage!,
            ),
          ],
        ],
      ),
    );
  }

  void _updateStyle(TextStyleSpec newSpec) {
    // Force rebuild of new spec object to trigger updates if passed by ref
    // Actually we modified it in place, so just notify callback.
    // Ideally should be immutable copy but for now this works with setState in parent.
    onStyleChanged(newSpec);
  }
}

class _FontButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final TextStyle? fontStyle;
  final VoidCallback onTap;

  const _FontButton({
    required this.label,
    required this.isSelected,
    this.fontStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: (fontStyle ?? const TextStyle()).copyWith(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StyleIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _StyleIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: isActive ? Colors.blue : Colors.black54,
      onPressed: onTap,
    );
  }
}
