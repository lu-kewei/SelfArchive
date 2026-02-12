import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../scene/models/node_entity.dart';

class RichTextEditingController extends TextEditingController {
  List<TextSpanSpec> _spans = [];
  TextStyleSpec _defaultStyle;

  // Style to apply to next inserted text
  TextStyleSpec? _composingStyle;

  // Callback to notify parent about spans update (for persistence)
  final Function(List<TextSpanSpec>) onSpansChanged;

  set defaultStyle(TextStyleSpec? value) {
    if (value != null && value != _defaultStyle) {
      _defaultStyle = value;
      notifyListeners();
    }
  }

  RichTextEditingController({
    String? text,
    List<TextSpanSpec>? initialSpans,
    required TextStyleSpec defaultStyle,
    required this.onSpansChanged,
  })  : _defaultStyle = defaultStyle,
        super(text: text) {
    if (initialSpans != null && initialSpans.isNotEmpty) {
      _spans = List.from(initialSpans);
    } else {
      _spans = [TextSpanSpec(text: text ?? '', style: defaultStyle)];
    }
    _normalizeSpansToText();
  }

  void _normalizeSpansToText() {
    final fullText = _spans.map((s) => s.text ?? '').join('');
    if (fullText != text) {
      if (text.isEmpty) {
        _spans = [];
      } else {
        _spans = [TextSpanSpec(text: text, style: _defaultStyle)];
      }
      onSpansChanged(_spans);
    }
  }

  // Update composing style (e.g. from toolbar)
  void setComposingStyle(TextStyleSpec? style) {
    _composingStyle = style;

    // If there is a selection, apply style to selection immediately
    if (selection.isValid && !selection.isCollapsed) {
      _applyStyleToSelection(style);
    } else {
      // If no selection, we want to update the style for next typed character.
      // But we also want to reflect the "current style" visually if possible?
      // No, TextField cursor doesn't show style.
      // But if we just move cursor and type, it should use this style.
      // The _applyChange logic uses _composingStyle if set.
      // So this is sufficient for typing.

      // However, if we just want to change the style of the *current word* or context when no selection?
      // Usually "T" button changes style for *selection* or *future text*.
      // If we want to support "click B to toggle Bold for current word", that's different.
      // Current requirement: "T button modifies text style".
      // Assuming "future text" if collapsed.
    }
  }

  void _applyStyleToSelection(TextStyleSpec? style) {
    final start = selection.start;
    final end = selection.end;
    if (start == end) return;

    final newSpans = <TextSpanSpec>[];
    int currentPos = 0;

    for (final span in _spans) {
      final spanText = span.text ?? '';
      final spanLen = spanText.length;
      final spanEnd = currentPos + spanLen;

      // Span is before selection
      if (spanEnd <= start) {
        newSpans.add(span);
      }
      // Span is after selection
      else if (currentPos >= end) {
        newSpans.add(span);
      }
      // Span overlaps selection
      else {
        // Calculate overlap
        final overlapStart = currentPos < start ? start - currentPos : 0;
        final overlapEnd = spanEnd > end ? end - currentPos : spanLen;

        // Part before selection
        if (overlapStart > 0) {
          newSpans.add(TextSpanSpec(
            text: spanText.substring(0, overlapStart),
            style: span.style,
          ));
        }

        // Selected part
        newSpans.add(TextSpanSpec(
          text: spanText.substring(overlapStart, overlapEnd),
          style: style, // Apply new style
        ));

        // Part after selection
        if (overlapEnd < spanLen) {
          newSpans.add(TextSpanSpec(
            text: spanText.substring(overlapEnd),
            style: span.style,
          ));
        }
      }
      currentPos += spanLen;
    }

    _spans = _mergeSpans(newSpans);
    onSpansChanged(_spans);
    notifyListeners(); // Trigger rebuild
  }

  List<TextSpanSpec> _mergeSpans(List<TextSpanSpec> spans) {
    if (spans.isEmpty) return [];
    spans = spans.where((s) => (s.text ?? '').isNotEmpty).toList();
    if (spans.isEmpty) return [];
    final merged = <TextSpanSpec>[];
    TextSpanSpec current = spans.first;

    for (int i = 1; i < spans.length; i++) {
      final next = spans[i];
      if (_areStylesEqual(current.style, next.style)) {
        current.text = (current.text ?? '') + (next.text ?? '');
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  bool _areStylesEqual(TextStyleSpec? a, TextStyleSpec? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.font == b.font &&
        a.size == b.size &&
        a.bold == b.bold &&
        a.italic == b.italic &&
        a.underline == b.underline &&
        a.highlight == b.highlight;
  }

  @override
  set value(TextEditingValue newValue) {
    // Detect changes and update spans
    if (newValue.text != text) {
      _updateSpansForTextChange(text, newValue.text, newValue.selection);
    }
    super.value = newValue;
  }

  void _updateSpansForTextChange(
      String oldText, String newText, TextSelection newSelection) {
    // Simple diff logic
    // 1. Find common prefix
    int prefixLen = 0;
    final minLen =
        oldText.length < newText.length ? oldText.length : newText.length;
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // 2. Find common suffix
    int suffixLen = 0;
    while (suffixLen < (minLen - prefixLen) &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    // 3. Determine change range
    final deleteCount = oldText.length - prefixLen - suffixLen;
    final insertText = newText.substring(prefixLen, newText.length - suffixLen);

    // 4. Update Spans
    // We need to delete `deleteCount` chars at `prefixLen`
    // And insert `insertText` at `prefixLen`

    // Reconstruct spans
    final newSpans = <TextSpanSpec>[];
    int currentPos = 0;

    // Style to use for insertion:
    // - If _composingStyle is set, use it.
    // - Else if inserting at end of a span, use that span's style.
    // - Else use default.
    TextStyleSpec? insertStyle = _composingStyle;

    for (final span in _spans) {
      final spanText = span.text ?? '';
      final spanLen = spanText.length;

      // Check if this span provides context for insertion style
      // If we are inserting exactly at the end of this span (and not composing style set), inherit
      if (insertStyle == null &&
          currentPos + spanLen == prefixLen &&
          deleteCount == 0 &&
          insertText.isNotEmpty) {
        insertStyle = span.style;
      }
      // If we are inserting inside this span
      if (insertStyle == null &&
          currentPos < prefixLen &&
          currentPos + spanLen > prefixLen) {
        insertStyle = span.style;
      }

      // Span is strictly before change range (prefix)
      if (currentPos + spanLen <= prefixLen) {
        newSpans.add(span);
        currentPos += spanLen;
        continue;
      }

      // Span is strictly after change range (suffix)
      if (currentPos >= prefixLen + deleteCount) {
        newSpans.add(span); // Add remaining part
        currentPos += spanLen;
        continue;
      }

      // Span is affected (overlap)

      // Keep prefix part of span
      if (currentPos < prefixLen) {
        final keepLen = prefixLen - currentPos;
        newSpans.add(TextSpanSpec(
            text: spanText.substring(0, keepLen), style: span.style));
      }

      // Skip deleted part
      // (Implicitly handled by not adding it)

      // Keep suffix part of span
      if (currentPos + spanLen > prefixLen + deleteCount) {
        final startInSpan = (prefixLen + deleteCount) - currentPos;
        // Ensure index is valid
        if (startInSpan >= 0 && startInSpan < spanLen) {
          newSpans.add(TextSpanSpec(
              text: spanText.substring(startInSpan), style: span.style));
        }
      }

      currentPos += spanLen;
    }

    // Insert new text
    if (insertText.isNotEmpty) {
      // Find insertion index in newSpans list
      // We can just rebuild the list properly or insert at correct position.
      // Since we iterated linearly, we can just insert the new text span
      // at the point where we switched from prefix to suffix.
      // But above loop structure is a bit rigid.

      // Let's try a simpler approach:
      // Rebuild entire list.
    }

    // RETHINK: The above loop is tricky to inject the insertion in the middle.
    // Easier: Split old spans into [Before, Deleted, After]
    // Then Construct [Before, Inserted, After]

    _spans = _applyChange(
        prefixLen, deleteCount, insertText, insertStyle ?? _defaultStyle);
    onSpansChanged(_spans);
  }

  List<TextSpanSpec> _applyChange(
      int start, int deleteCount, String insertText, TextStyleSpec style) {
    final result = <TextSpanSpec>[];
    int currentPos = 0;

    // 1. Process Spans to keep (Prefix)
    for (final span in _spans) {
      final spanText = span.text ?? '';
      final spanLen = spanText.length;

      if (currentPos + spanLen <= start) {
        result.add(span);
        currentPos += spanLen;
      } else if (currentPos < start) {
        // Partial keep
        result.add(TextSpanSpec(
            text: spanText.substring(0, start - currentPos),
            style: span.style));
        currentPos +=
            spanLen; // effectively processed this span logic-wise for prefix
      } else {
        break; // Reached change point
      }
    }

    // 2. Add Inserted Text
    if (insertText.isNotEmpty) {
      result.add(TextSpanSpec(text: insertText, style: style));
    }

    // 3. Process Spans to keep (Suffix)
    // We need to skip `start + deleteCount` characters from original spans
    int skipUntil = start + deleteCount;
    currentPos = 0;

    for (final span in _spans) {
      final spanText = span.text ?? '';
      final spanLen = spanText.length;

      if (currentPos + spanLen <= skipUntil) {
        // Fully skipped
      } else if (currentPos < skipUntil) {
        // Partial skip
        result.add(TextSpanSpec(
            text: spanText.substring(skipUntil - currentPos),
            style: span.style));
      } else {
        // Fully keep
        result.add(span);
      }
      currentPos += spanLen;
    }

    return _mergeSpans(result);
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    // `style` contains the base text style from TextField (including fontSize calculated from node scale)
    final baseFontSize = style?.fontSize ?? 14.0;
    final baseStyle = (style ?? const TextStyle()).copyWith(
      fontSize: baseFontSize,
    );
    final filteredSpans =
        _spans.where((s) => (s.text ?? '').isNotEmpty).toList();
    final spansText = filteredSpans.map((s) => s.text ?? '').join('');
    if (spansText != text) {
      return TextSpan(
        style: baseStyle,
        text: text,
      );
    }

    return TextSpan(
      style: baseStyle,
      children: filteredSpans.map((span) {
        return TextSpan(
          text: span.text,
          style: _convertStyle(span.style, baseFontSize),
        );
      }).toList(),
    );
  }

  TextStyle _convertStyle(TextStyleSpec? spec, double baseFontSize) {
    if (spec == null) {
      return TextStyle(fontSize: baseFontSize);
    }

    // Font Family
    String? fontFamily;
    if (spec.font == TextFontPreset.vintage) {
      fontFamily = GoogleFonts.zcoolXiaoWei().fontFamily;
    } else if (spec.font == TextFontPreset.handwriting) {
      fontFamily = GoogleFonts.maShanZheng().fontFamily;
    } else if (spec.font == TextFontPreset.rational) {
      fontFamily = GoogleFonts.notoSansSc().fontFamily;
    }

    // Font Size Calculation
    // TextField.style has (Base * NodeScale)
    // We want (Base * NodeScale * SizePreset)
    // But if spec.size is Medium, we want exactly Base * NodeScale.
    // So we apply multiplier to baseFontSize.
    double fontSize = baseFontSize;
    if (spec.size == TextSizePreset.small) {
      fontSize = baseFontSize * 0.80;
    } else if (spec.size == TextSizePreset.large) {
      fontSize = baseFontSize * 1.75;
    }

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: spec.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: spec.italic ? FontStyle.italic : FontStyle.normal,
      decoration:
          spec.underline ? TextDecoration.underline : TextDecoration.none,
      backgroundColor:
          spec.highlight ? Colors.yellow.withValues(alpha: 0.3) : null,
    );
  }
}
