import 'package:flutter/material.dart';

class FormatStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;

  const FormatStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
  });

  FormatStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
  }) {
    return FormatStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormatStyle &&
          runtimeType == other.runtimeType &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikethrough == other.strikethrough;

  @override
  int get hashCode => Object.hash(bold, italic, underline, strikethrough);
}

/// A true RichTextEditingController that maintains visual formatting per character range
/// without polluting the editing field with raw markdown or HTML markup syntax tags.
class RichTextEditingController extends TextEditingController {
  final List<FormatStyle> _charStyles = [];
  FormatStyle activeStyle = const FormatStyle();
  String _previousText = '';

  RichTextEditingController({String? initialHtml}) {
    if (initialHtml != null && initialHtml.isNotEmpty) {
      loadHtml(initialHtml);
    }
    _previousText = text;
    addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentText = text;
    if (currentText == _previousText) return;

    final diff = currentText.length - _previousText.length;
    if (diff > 0) {
      // Insertion: User typed or pasted text
      final sel = selection;
      int insertIndex = sel.isValid ? sel.start - diff : _previousText.length;
      if (insertIndex < 0) insertIndex = 0;
      if (insertIndex > _charStyles.length) insertIndex = _charStyles.length;

      final insertedStyles = List.generate(diff, (_) => activeStyle);
      _charStyles.insertAll(insertIndex, insertedStyles);
    } else if (diff < 0) {
      // Deletion: User deleted characters
      final sel = selection;
      int deleteIndex = sel.isValid ? sel.start : currentText.length;
      int count = -diff;
      if (deleteIndex >= 0 && deleteIndex + count <= _charStyles.length) {
        _charStyles.removeRange(deleteIndex, deleteIndex + count);
      } else {
        while (_charStyles.length > currentText.length) {
          _charStyles.removeLast();
        }
      }
    }

    _previousText = currentText;
    _updateActiveStyleFromSelection();
  }

  void _updateActiveStyleFromSelection() {
    if (!selection.isValid) return;
    if (_charStyles.isEmpty) return;

    final pos = selection.start;
    if (pos > 0 && pos <= _charStyles.length) {
      activeStyle = _charStyles[pos - 1];
    }
  }

  void toggleBold() {
    _toggleStyle((s) => s.copyWith(bold: !s.bold));
  }

  void toggleItalic() {
    _toggleStyle((s) => s.copyWith(italic: !s.italic));
  }

  void toggleUnderline() {
    _toggleStyle((s) => s.copyWith(underline: !s.underline));
  }

  void toggleStrikethrough() {
    _toggleStyle((s) => s.copyWith(strikethrough: !s.strikethrough));
  }

  void _toggleStyle(FormatStyle Function(FormatStyle) transform) {
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start.clamp(0, _charStyles.length);
      final end = selection.end.clamp(0, _charStyles.length);
      for (int i = start; i < end; i++) {
        _charStyles[i] = transform(_charStyles[i]);
      }
      notifyListeners();
    } else {
      activeStyle = transform(activeStyle);
      notifyListeners();
    }
  }

  void clearFormatting() {
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start.clamp(0, _charStyles.length);
      final end = selection.end.clamp(0, _charStyles.length);
      for (int i = start; i < end; i++) {
        _charStyles[i] = const FormatStyle();
      }
    } else {
      activeStyle = const FormatStyle();
    }
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    if (text.isEmpty || _charStyles.length != text.length) {
      return TextSpan(text: text, style: baseStyle);
    }

    final List<InlineSpan> spans = [];
    int start = 0;

    while (start < text.length) {
      final currentFormat = _charStyles[start];
      int end = start + 1;
      while (end < text.length && _charStyles[end] == currentFormat) {
        end++;
      }

      TextStyle runStyle = baseStyle;
      if (currentFormat.bold) {
        runStyle = runStyle.copyWith(fontWeight: FontWeight.bold);
      }
      if (currentFormat.italic) {
        runStyle = runStyle.copyWith(fontStyle: FontStyle.italic);
      }
      TextDecoration decoration = TextDecoration.none;
      if (currentFormat.underline && currentFormat.strikethrough) {
        decoration = TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]);
      } else if (currentFormat.underline) {
        decoration = TextDecoration.underline;
      } else if (currentFormat.strikethrough) {
        decoration = TextDecoration.lineThrough;
      }
      if (decoration != TextDecoration.none) {
        runStyle = runStyle.copyWith(decoration: decoration);
      }

      spans.add(TextSpan(
        text: text.substring(start, end),
        style: runStyle,
      ));

      start = end;
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  /// Converts plain text + style ranges into clean HTML string for persistent storage
  String toFormattedString() {
    if (text.isEmpty || _charStyles.length != text.length) {
      return text;
    }

    final buffer = StringBuffer();
    int start = 0;

    while (start < text.length) {
      final fmt = _charStyles[start];
      int end = start + 1;
      while (end < text.length && _charStyles[end] == fmt) {
        end++;
      }

      String chunk = text.substring(start, end);
      if (fmt.bold) chunk = '<strong>$chunk</strong>';
      if (fmt.italic) chunk = '<em>$chunk</em>';
      if (fmt.underline) chunk = '<u>$chunk</u>';
      if (fmt.strikethrough) chunk = '<s>$chunk</s>';

      buffer.write(chunk);
      start = end;
    }

    return buffer.toString();
  }

  /// Loads HTML or Markdown string into plain text and character style ranges
  void loadHtml(String input) {
    _charStyles.clear();
    final plainTextBuffer = StringBuffer();

    final regExp = RegExp(
      r'<(strong|b|em|i|u|s|strike)>(.*?)<\/\1>|\*\*(.*?)\*\*|\*(.*?)\*|<u>(.*?)<\/u>|~~(.*?)~~',
      caseSensitive: false,
      dotAll: true,
    );

    int lastEnd = 0;
    for (final match in regExp.allMatches(input)) {
      if (match.start > lastEnd) {
        final plainChunk = input.substring(lastEnd, match.start);
        plainTextBuffer.write(plainChunk);
        _charStyles.addAll(List.generate(plainChunk.length, (_) => const FormatStyle()));
      }

      final tag = match.group(1)?.toLowerCase();
      String content = '';
      FormatStyle style = const FormatStyle();

      if (tag != null) {
        content = match.group(2) ?? '';
        if (tag == 'strong' || tag == 'b') style = style.copyWith(bold: true);
        if (tag == 'em' || tag == 'i') style = style.copyWith(italic: true);
        if (tag == 'u') style = style.copyWith(underline: true);
        if (tag == 's' || tag == 'strike') style = style.copyWith(strikethrough: true);
      } else if (match.group(0)!.startsWith('**')) {
        content = match.group(3) ?? '';
        style = style.copyWith(bold: true);
      } else if (match.group(0)!.startsWith('*')) {
        content = match.group(4) ?? '';
        style = style.copyWith(italic: true);
      } else if (match.group(0)!.startsWith('<u>')) {
        content = match.group(5) ?? '';
        style = style.copyWith(underline: true);
      } else if (match.group(0)!.startsWith('~~')) {
        content = match.group(6) ?? '';
        style = style.copyWith(strikethrough: true);
      }

      plainTextBuffer.write(content);
      _charStyles.addAll(List.generate(content.length, (_) => style));
      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      final plainChunk = input.substring(lastEnd);
      plainTextBuffer.write(plainChunk);
      _charStyles.addAll(List.generate(plainChunk.length, (_) => const FormatStyle()));
    }

    text = plainTextBuffer.toString();
    _previousText = text;
  }
}
