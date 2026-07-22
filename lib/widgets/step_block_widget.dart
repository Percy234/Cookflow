import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/step_block.dart';
import 'app_theme.dart';
import 'app_image.dart';

class StepBlockWidget extends StatefulWidget {
  final StepBlock block;

  const StepBlockWidget({super.key, required this.block});

  @override
  State<StepBlockWidget> createState() => _StepBlockWidgetState();
}

class _StepBlockWidgetState extends State<StepBlockWidget> {
  // Local state for checkboxes and checklists
  bool _checkboxValue = false;
  List<bool> _checklistValues = [];

  @override
  void initState() {
    super.initState();
    _initLocalState();
  }

  @override
  void didUpdateWidget(covariant StepBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id || oldWidget.block.content != widget.block.content) {
      _initLocalState();
    }
  }

  void _initLocalState() {
    if (widget.block.type == BlockType.checkbox) {
      _checkboxValue = false;
    } else if (widget.block.type == BlockType.checklist) {
      try {
        List<dynamic> items = jsonDecode(widget.block.content);
        _checklistValues = List.generate(items.length, (_) => false);
      } catch (_) {
        _checklistValues = [];
      }
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final val = int.tryParse(hex, radix: 16);
    if (val != null) return Color(val);
    return null;
  }

  /// Returns the text color to use:
  /// - If user set a custom color → use it as-is.
  /// - If no color set (default) → use theme-aware textPrimary so dark-mode works.
  Color _resolveTextColor(BuildContext context) {
    final custom = _parseColor(widget.block.color);
    return custom ?? context.colors.textPrimary;
  }

  TextStyle _getTextStyle(BuildContext context, {double defaultSize = 16.0, bool isHeading = false}) {
    final b = widget.block;
    final baseStyle = isHeading ? AppTextStyles.displayLarge : AppTextStyles.bodyLarge;
    return baseStyle.copyWith(
      fontWeight: (b.isBold ?? isHeading) ? FontWeight.bold : FontWeight.normal,
      fontStyle: (b.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
      decoration: (b.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
      fontSize: b.fontSize ?? defaultSize,
      color: _resolveTextColor(context),
    );
  }

  TextAlign _getTextAlign() {
    final ta = widget.block.textAlign;
    if (ta == 'center') return TextAlign.center;
    if (ta == 'right') return TextAlign.right;
    return TextAlign.left;
  }

  Alignment _getAlignment() {
    final ta = widget.block.textAlign;
    if (ta == 'center') return Alignment.center;
    if (ta == 'right') return Alignment.centerRight;
    return Alignment.centerLeft;
  }

  WrapAlignment _getWrapAlignment() {
    final ta = widget.block.textAlign;
    if (ta == 'center') return WrapAlignment.center;
    if (ta == 'right') return WrapAlignment.end;
    return WrapAlignment.start;
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;

    switch (block.type) {
      case BlockType.heading:
        double defaultSize = 32.0;
        switch (block.headingLevel) {
          case 'h2': defaultSize = 26.0; break;
          case 'h3': defaultSize = 22.0; break;
          case 'h4': defaultSize = 18.0; break;
          case 'h5': defaultSize = 16.0; break;
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            block.content,
            style: _getTextStyle(context, defaultSize: defaultSize, isHeading: true),
            textAlign: _getTextAlign(),
          ),
        );

      case BlockType.text:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            block.content,
            style: _getTextStyle(context, defaultSize: 16.0),
            textAlign: _getTextAlign(),
          ),
        );

      case BlockType.image:
        if (block.content.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Align(
            alignment: _getAlignment(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(
                imagePath: block.content,
                fit: BoxFit.cover,
                width: block.width ?? double.infinity,
                height: block.height,
              ),
            ),
          ),
        );

      case BlockType.images:
        List<dynamic> paths = [];
        try {
          paths = jsonDecode(block.content);
        } catch (_) {}
        if (paths.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: _getWrapAlignment(),
              spacing: 8,
              runSpacing: 8,
              children: paths.map((p) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: block.width ?? 120, 
                  height: block.height ?? 120,
                  child: AppImage(imagePath: p.toString(), fit: BoxFit.cover),
                ),
              )).toList(),
            ),
          ),
        );

      case BlockType.checkbox:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _checkboxValue = !_checkboxValue;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _checkboxValue ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: _checkboxValue ? AppColors.primary : AppColors.textSecondary, 
                      width: 2
                    ),
                    shape: block.listStyle == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: block.listStyle == 'circle' ? null : BorderRadius.circular(6),
                  ),
                  child: _checkboxValue 
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                Expanded(
                  child: Text(
                    block.content,
                    style: _getTextStyle(context).copyWith(
                      decoration: _checkboxValue ? TextDecoration.lineThrough : null,
                      color: _checkboxValue
                          ? context.colors.textHint
                          : _resolveTextColor(context),
                    ),
                    textAlign: _getTextAlign(),
                  ),
                ),
              ],
            ),
          ),
        );

      case BlockType.checklist:
        List<dynamic> items = [];
        try { items = jsonDecode(block.content); } catch (_) {}
        if (items.isEmpty) return const SizedBox.shrink();

        if (_checklistValues.length != items.length) {
          _checklistValues = List.generate(items.length, (_) => false);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> item = entry.value;
              String text = item['text'] ?? '';
              bool isChecked = _checklistValues[idx];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _checklistValues[idx] = !isChecked;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2, right: 12),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isChecked ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isChecked ? AppColors.primary : AppColors.textSecondary, 
                            width: 2
                          ),
                          shape: block.listStyle == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: block.listStyle == 'circle' ? null : BorderRadius.circular(6),
                        ),
                        child: isChecked 
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          text,
                          style: _getTextStyle(context).copyWith(
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            color: isChecked
                                ? context.colors.textHint
                                : _resolveTextColor(context),
                          ),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );

      case BlockType.ordered:
        List<dynamic> orderedItems = [];
        try { orderedItems = jsonDecode(block.content); } catch (_) {}
        if (orderedItems.isEmpty) return const SizedBox.shrink();

        String getPrefix(int idx) {
          final ls = block.listStyle;
          if (ls == 'bullet') return '•';
          if (ls == 'hyphen') return '-';
          if (ls == 'roman') {
            const romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV'];
            if (idx < romans.length) return '${romans[idx]}.';
            return '${idx + 1}.';
          }
          return '${idx + 1}.';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: orderedItems.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> item = entry.value;
              String text = item['text'] ?? '';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.topRight,
                      child: Text(
                        getPrefix(idx),
                        style: _getTextStyle(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: _getTextStyle(context),
                        textAlign: _getTextAlign(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );

      case BlockType.column:
        Map<String, dynamic> colData = {};
        try {
          final decoded = jsonDecode(block.content);
          if (decoded is Map) colData = Map<String, dynamic>.from(decoded);
        } catch (_) {}
        List<dynamic> cols = colData['cols'] ?? [];
        if (cols.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cols.map((colDef) {
              List<dynamic> subBlockData = colDef['blocks'] ?? [];
              List<StepBlock> subBlocks = subBlockData.map((d) {
                return StepBlock(
                  id: d['id'] ?? '',
                  type: BlockType.values.firstWhere((e) => e.name == d['type'], orElse: () => BlockType.text),
                  content: d['content'] ?? '',
                  color: d['color'],
                  fontSize: d['fontSize']?.toDouble(),
                  isBold: d['isBold'],
                  isItalic: d['isItalic'],
                  isUnderline: d['isUnderline'],
                  textAlign: d['textAlign'],
                  headingLevel: d['headingLevel'],
                  listStyle: d['listStyle'],
                  width: d['width']?.toDouble(),
                  height: d['height']?.toDouble(),
                );
              }).toList();
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subBlocks.map((sb) => StepBlockWidget(block: sb)).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        );

      case BlockType.row:
        Map<String, dynamic> rowData = {};
        try {
          final decoded = jsonDecode(block.content);
          if (decoded is Map) rowData = Map<String, dynamic>.from(decoded);
        } catch (_) {}
        List<dynamic> rows = rowData['rows'] ?? [];
        if (rows.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: rows.map((rowDef) {
              List<dynamic> subBlockData = rowDef['blocks'] ?? [];
              List<StepBlock> subBlocks = subBlockData.map((d) {
                return StepBlock(
                  id: d['id'] ?? '',
                  type: BlockType.values.firstWhere((e) => e.name == d['type'], orElse: () => BlockType.text),
                  content: d['content'] ?? '',
                  color: d['color'],
                  fontSize: d['fontSize']?.toDouble(),
                  isBold: d['isBold'],
                  isItalic: d['isItalic'],
                  isUnderline: d['isUnderline'],
                  textAlign: d['textAlign'],
                  headingLevel: d['headingLevel'],
                  listStyle: d['listStyle'],
                  width: d['width']?.toDouble(),
                  height: d['height']?.toDouble(),
                );
              }).toList();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subBlocks.map((sb) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: StepBlockWidget(block: sb),
                    ),
                  )).toList(),
                ),
              );
            }).toList(),
          ),
        );

      case BlockType.table:
        List<dynamic> grid = [];
        try { grid = jsonDecode(block.content); } catch (_) {}
        if (grid.isEmpty) return const SizedBox.shrink();

        // Use theme-aware colors for border and cell background (default path)
        final tableBorderColor = context.colors.divider;
        final tableCellBg = context.colors.surface;
        final tableCellTextStyle = AppTextStyles.bodyMedium.copyWith(
          color: context.colors.textPrimary,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Table(
            border: TableBorder.all(
              color: tableBorderColor,
              width: 1,
              borderRadius: BorderRadius.circular(8),
            ),
            children: grid.map<TableRow>((row) {
              List<dynamic> cells = row;
              return TableRow(
                decoration: BoxDecoration(color: tableCellBg),
                children: cells.map<Widget>((cellText) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      cellText.toString(),
                      style: tableCellTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );

      case BlockType.spacer:
        // Spacer: always renders, height from JSON content {'height': N}
        double spacerH = 32;
        try {
          final decoded = jsonDecode(block.content);
          if (decoded is Map && decoded['height'] != null) {
            spacerH = (decoded['height'] as num).toDouble();
          }
        } catch (_) {}
        return SizedBox(height: spacerH);

      default:
        return const SizedBox.shrink();
    }
  }
}
