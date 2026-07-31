import 'package:flutter/material.dart';

/// Component hiển thị văn bản định dạng cơ bản (Bold, Italic, Underline, Strikethrough, Bullet list).
class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const FormattedText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final defaultStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = _parseMarkdown(text, defaultStyle);

    return Text.rich(
      TextSpan(children: spans),
      style: defaultStyle,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  static List<InlineSpan> _parseMarkdown(String input, TextStyle baseStyle) {
    final List<InlineSpan> result = [];
    final lines = input.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (i > 0) {
        result.add(const TextSpan(text: '\n'));
      }

      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.startsWith('• ')) {
        result.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        line = line.replaceFirst(RegExp(r'^\s*•\s*'), '');
      } else if (trimmedLeft.startsWith('- ')) {
        result.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        line = line.replaceFirst(RegExp(r'^\s*-\s*'), '');
      } else {
        final matchNum = RegExp(r'^\s*(\d+\.)\s+').firstMatch(line);
        if (matchNum != null) {
          final prefix = matchNum.group(1)!;
          result.add(TextSpan(
            text: '$prefix ',
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ));
          line = line.replaceFirst(RegExp(r'^\s*\d+\.\s+'), '');
        }
      }

      _parseInlineStyles(line, baseStyle, result);
    }

    return result;
  }

  static void _parseInlineStyles(String text, TextStyle baseStyle, List<InlineSpan> spans) {
    final pattern = RegExp(
      r'<(strong|b|em|i|u|s|strike)>(.*?)<\/\1>|\*\*(.*?)\*\*|\*(.*?)\*|~~(.*?)~~|<u>(.*?)<\/u>',
      caseSensitive: false,
      dotAll: true,
    );

    int lastMatchEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: baseStyle));
      }

      final tag = match.group(1)?.toLowerCase();
      if (tag != null) {
        final content = match.group(2) ?? '';
        TextStyle runStyle = baseStyle;
        if (tag == 'strong' || tag == 'b') runStyle = runStyle.copyWith(fontWeight: FontWeight.bold);
        if (tag == 'em' || tag == 'i') runStyle = runStyle.copyWith(fontStyle: FontStyle.italic);
        if (tag == 'u') runStyle = runStyle.copyWith(decoration: TextDecoration.underline);
        if (tag == 's' || tag == 'strike') runStyle = runStyle.copyWith(decoration: TextDecoration.lineThrough);

        _parseInlineStyles(content, runStyle, spans);
      } else {
        final fullMatch = match.group(0)!;
        if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
          final content = match.group(3) ?? '';
          _parseInlineStyles(content, baseStyle.copyWith(fontWeight: FontWeight.bold), spans);
        } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
          final content = match.group(4) ?? '';
          _parseInlineStyles(content, baseStyle.copyWith(fontStyle: FontStyle.italic), spans);
        } else if (fullMatch.startsWith('~~') && fullMatch.endsWith('~~')) {
          final content = match.group(5) ?? '';
          _parseInlineStyles(content, baseStyle.copyWith(decoration: TextDecoration.lineThrough), spans);
        } else if (fullMatch.startsWith('<u>') && fullMatch.endsWith('</u>')) {
          final content = match.group(6) ?? '';
          _parseInlineStyles(content, baseStyle.copyWith(decoration: TextDecoration.underline), spans);
        }
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }
  }
}
