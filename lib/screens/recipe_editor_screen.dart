import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../models/recipe_page.dart';
import '../models/step_block.dart';
import '../models/step_model.dart';
import '../services/hive_service.dart';
import '../widgets/app_theme.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_image.dart';
import 'package:provider/provider.dart';
import 'recipe_detail_screen.dart';

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeEditorScreen({super.key, this.recipe});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  bool _isPreviewMode = false;
  int _selectedPageIndex = 0;
  List<RecipePage> _pages = [RecipePage(id: const Uuid().v4(), name: 'Trang 1')];
  final Map<String, List<StepBlock>> _pageBlocks = {};

  List<StepBlock> get _blocks {
    final pageId = _pages[_selectedPageIndex].id;
    if (!_pageBlocks.containsKey(pageId)) {
      _pageBlocks[pageId] = [];
    }
    return _pageBlocks[pageId]!;
  }
  String? _selectedBlockId;
  int? _selectedColIdx;
  StepBlock? _focusedStyleBlock;
  VoidCallback? _onFocusedStyleBlockChanged;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      if (widget.recipe!.pages != null && widget.recipe!.pages!.isNotEmpty) {
        _pages = List.from(widget.recipe!.pages!);
      }
      // Load steps from Hive
      for (final p in _pages) {
        if (p.stepIds.isNotEmpty) {
          final step = HiveService.stepsBox.get(p.stepIds.first);
          _pageBlocks[p.id] = step?.blocks ?? [];
        } else {
          _pageBlocks[p.id] = [];
        }
      }
    } else {
      _pageBlocks[_pages.first.id] = [];
    }
  }

  void _addBlock(String type) {
    setState(() {
      final id = const Uuid().v4();
      final newBlockType = _parseBlockTypeFromString(type);
      final newContent = _getDefaultContentForBlockType(newBlockType);

      if (_selectedBlockId != null) {
        final parentIdx = _blocks.indexWhere((b) => b.id == _selectedBlockId);
        if (parentIdx != -1) {
          final parentBlock = _blocks[parentIdx];
          
          if (parentBlock.type == BlockType.column && _selectedColIdx != null) {
            Map<String, dynamic> colData = {};
            try {
              final decoded = jsonDecode(parentBlock.content);
              if (decoded is Map) colData = Map<String, dynamic>.from(decoded);
            } catch (_) {}

            List<dynamic> cols = List<dynamic>.from(colData['cols'] ?? []);
            if (_selectedColIdx! < cols.length) {
              final col = Map<String, dynamic>.from(cols[_selectedColIdx!]);
              final subBlocks = List<dynamic>.from(col['blocks'] ?? []);
              
              subBlocks.add({
                'id': id,
                'type': newBlockType.name,
                'content': newContent,
              });
              cols[_selectedColIdx!]['blocks'] = subBlocks;
              parentBlock.content = jsonEncode({'cols': cols});
              return;
            }
          } else if (parentBlock.type == BlockType.row && _selectedColIdx != null) {
            Map<String, dynamic> rowData = {};
            try {
              final decoded = jsonDecode(parentBlock.content);
              if (decoded is Map) rowData = Map<String, dynamic>.from(decoded);
            } catch (_) {}

            List<dynamic> rows = List<dynamic>.from(rowData['rows'] ?? []);
            if (_selectedColIdx! < rows.length) {
              final row = Map<String, dynamic>.from(rows[_selectedColIdx!]);
              final subBlocks = List<dynamic>.from(row['blocks'] ?? []);
              
              subBlocks.add({
                'id': id,
                'type': newBlockType.name,
                'content': newContent,
              });
              rows[_selectedColIdx!]['blocks'] = subBlocks;
              parentBlock.content = jsonEncode({'rows': rows});
              return;
            }
          }
        }
      }

      _blocks.add(StepBlock(id: id, type: newBlockType, content: newContent));
    });
  }

  BlockType _parseBlockTypeFromString(String type) {
    switch (type) {
      case 'heading': return BlockType.heading;
      case 'p': return BlockType.text;
      case 'img': return BlockType.image;
      case 'imgs': return BlockType.images;
      case 'checkbox': return BlockType.checkbox;
      case 'checklist': return BlockType.checklist;
      case 'ordered': return BlockType.ordered;
      case 'col': return BlockType.column;
      case 'row': return BlockType.row;
      case 'table': return BlockType.table;
      default: return BlockType.text;
    }
  }

  String _getDefaultContentForBlockType(BlockType type) {
    switch (type) {
      case BlockType.heading: return '';
      case BlockType.text: return '';
      case BlockType.image: return '';
      case BlockType.images: return jsonEncode([]);
      case BlockType.checkbox: return '';
      case BlockType.checklist: return jsonEncode([{"text": "", "checked": false}]);
      case BlockType.ordered: return jsonEncode([{"text": ""}]);
      case BlockType.column: return jsonEncode({
          'cols': [
            {'blocks': []},
            {'blocks': []},
          ]
        });
      case BlockType.row: return jsonEncode({
          'rows': [
            {'blocks': []},
            {'blocks': []},
          ]
        });
      case BlockType.table: return jsonEncode([["", ""], ["", ""]]);
    }
  }

  Future<void> _pickSingleImage(StepBlock block, {VoidCallback? onContentChanged}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        block.content = picked.path;
        onContentChanged?.call();
      });
    }
  }

  Future<void> _pickMultipleImages(StepBlock block, {VoidCallback? onContentChanged}) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      List<String> paths = picked.map((e) => e.path).toList();
      setState(() {
        block.content = jsonEncode(paths);
        onContentChanged?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(widget.recipe != null 
            ? 'Chỉnh sửa quy trình: ${widget.recipe!.name}' 
            : 'Chỉnh sửa quy trình'),
        backgroundColor: context.colors.background,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            _selectedBlockId = null;
            _selectedColIdx = null;
            _focusedStyleBlock = null;
          });
          FocusScope.of(context).unfocus();
        },
        child: Column(
        children: [
          if (!_isPreviewMode) _buildToolbar(),
          if (!_isPreviewMode) const Divider(height: 1),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: _isPreviewMode ? (details) {
                if (details.primaryVelocity! > 300) {
                  // Vuốt phải -> Trang trước
                  if (_selectedPageIndex > 0) {
                    setState(() {
                      _selectedPageIndex--;
                      _selectedBlockId = null;
                      _selectedColIdx = null;
                      _focusedStyleBlock = null;
                    });
                  }
                } else if (details.primaryVelocity! < -300) {
                  // Vuốt trái -> Trang sau
                  if (_selectedPageIndex < _pages.length - 1) {
                    setState(() {
                      _selectedPageIndex++;
                      _selectedBlockId = null;
                      _selectedColIdx = null;
                      _focusedStyleBlock = null;
                    });
                  }
                }
              } : null,
              child: Stack(
              children: [
                _blocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_document, size: 64, color: context.colors.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'Trang giấy trắng',
                              style: context.textTheme.headlineMedium!.copyWith(color: context.colors.textHint),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chọn một công cụ phía trên để bắt đầu thêm nội dung.',
                              style: context.textTheme.bodyMedium!.copyWith(color: context.colors.textHint),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          left: 24, right: 24, top: 16, 
                          bottom: _focusedStyleBlock != null ? 300 : 56
                        ),
                        itemCount: _blocks.length,
                        itemBuilder: (context, index) {
                          return IgnorePointer(
                            ignoring: _isPreviewMode,
                            child: _buildBlockWrapper(_blocks[index], index),
                          );
                        },
                      ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildTabBar(),
                ),
                Positioned(
                  bottom: 64, // 48 (TabBar height) + 16 (spacing)
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Hoàn thành', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        // Save all _pageBlocks into StepModels in Hive
                        for (final page in _pages) {
                          String stepId;
                          if (page.stepIds.isNotEmpty) {
                            stepId = page.stepIds.first;
                          } else {
                            stepId = const Uuid().v4();
                            page.stepIds = [stepId];
                          }
                          
                          final stepType = page.type == 'timer' ? StepType.timerStep : StepType.staticStep;
                          final stepModel = StepModel(
                            id: stepId,
                            name: page.name,
                            type: stepType,
                            durationSeconds: page.duration,
                            blocks: _pageBlocks[page.id] ?? [],
                          );
                          await HiveService.stepsBox.put(stepId, stepModel);
                        }

                        // Navigate to RecipeDetailScreen
                        if (widget.recipe != null) {
                          final provider = context.read<RecipeProvider>();
                          final finalRecipe = widget.recipe!.copyWith(pages: _pages);

                          final exists = provider.recipes.any((r) => r.id == finalRecipe.id);
                          if (exists) {
                            await provider.updateRecipe(finalRecipe);
                          } else {
                            await provider.addRecipe(finalRecipe);
                          }

                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(recipeId: finalRecipe.id),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isPreviewMode && _pages.isNotEmpty && _pages[_selectedPageIndex].type == 'timer')
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.timer, size: 20),
                            color: context.colors.primary,
                            tooltip: 'Cài đặt thời gian',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            onPressed: _showTimerSettingsDialog,
                          ),
                        ),
                      if (!_isPreviewMode && _pages.isNotEmpty && _pages[_selectedPageIndex].type == 'timer')
                        const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _isPreviewMode ? context.colors.primary : context.colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isPreviewMode ? Colors.transparent : context.colors.divider),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: IconButton(
                          icon: Icon(_isPreviewMode ? Icons.edit_rounded : Icons.preview_rounded, size: 20),
                          color: _isPreviewMode ? Colors.white : context.colors.textPrimary,
                          tooltip: _isPreviewMode ? 'Chỉnh sửa' : 'Xem trước',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          onPressed: () {
                            setState(() {
                              _isPreviewMode = !_isPreviewMode;
                              if (_isPreviewMode) {
                                _selectedBlockId = null;
                                _selectedColIdx = null;
                                _focusedStyleBlock = null;
                              }
                            });
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_focusedStyleBlock != null)
                  NotificationListener<DraggableScrollableNotification>(
                    onNotification: (_) => true,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                      ),
                      child: DraggableScrollableSheet(
                        controller: _sheetController,
                        initialChildSize: 0.08,
                        minChildSize: 0.08,
                        maxChildSize: 0.5,
                        builder: (_, controller) {
                          return Container(
                            decoration: BoxDecoration(
                              color: context.colors.surfaceElevated,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
                            ),
                            child: GestureDetector(
                              onTap: () {},
                              behavior: HitTestBehavior.opaque,
                              child: _StyleEditorPanel(
                                block: _focusedStyleBlock!,
                                scrollController: controller,
                                onStyleChanged: _onFocusedStyleBlockChanged ?? () => setState((){}),
                                onPickImage: () {
                                  if (_focusedStyleBlock!.type == BlockType.image) {
                                    _pickSingleImage(_focusedStyleBlock!, onContentChanged: _onFocusedStyleBlockChanged);
                                  } else if (_focusedStyleBlock!.type == BlockType.images) {
                                    _pickMultipleImages(_focusedStyleBlock!, onContentChanged: _onFocusedStyleBlockChanged);
                                  }
                                },
                                onHandleTapped: () {
                                  if (_sheetController.isAttached) {
                                    if (_sheetController.size < 0.2) {
                                      _sheetController.animateTo(0.5, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                                    } else {
                                      _sheetController.animateTo(0.08, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedPageIndex == index;
                final page = _pages[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedPageIndex = index),
                  onDoubleTap: _isPreviewMode ? null : () => _showRenamePageDialog(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.surfaceElevated : context.colors.surface,
                      border: Border(
                        bottom: BorderSide(color: isSelected ? context.colors.primary : Colors.transparent, width: 2),
                        right: BorderSide(color: context.colors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            if (page.type == 'timer') ...[
                              Icon(Icons.timer_outlined, size: 14, color: isSelected ? context.colors.primary : context.colors.textSecondary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              page.name,
                              style: context.textTheme.labelLarge!.copyWith(
                                color: isSelected ? context.colors.primary : context.colors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (!_isPreviewMode && _pages.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deletePage(index),
                            child: Icon(Icons.close, size: 14, color: context.colors.textHint),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_isPreviewMode)
            IconButton(
              icon: Icon(Icons.add, color: context.colors.textPrimary),
              onPressed: _addNewPage,
              tooltip: 'Thêm trang mới',
            ),
        ],
      ),
    );
  }

  void _addNewPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceElevated,
        title: Text('Chọn loại bước', style: context.textTheme.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.article_outlined, color: context.colors.primary),
              title: const Text('Static Step'),
              subtitle: const Text('Bước hướng dẫn thông thường'),
              onTap: () {
                Navigator.pop(context);
                _createPage('static');
              },
            ),
            ListTile(
              leading: Icon(Icons.timer_outlined, color: context.colors.primary),
              title: const Text('Timer Step'),
              subtitle: const Text('Bước có đếm thời gian'),
              onTap: () {
                Navigator.pop(context);
                _createPage('timer');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createPage(String type) {
    setState(() {
      final newPage = RecipePage(
        id: const Uuid().v4(), 
        name: 'Trang ${_pages.length + 1}',
        type: type,
        duration: type == 'timer' ? 300 : null, // Default 5 minutes
      );
      _pages.add(newPage);
      _pageBlocks[newPage.id] = [];
      _selectedPageIndex = _pages.length - 1;
    });
  }

  void _showTimerSettingsDialog() {
    final page = _pages[_selectedPageIndex];
    int currentDuration = page.duration ?? 300;
    int currentMin = currentDuration ~/ 60;
    int currentSec = currentDuration % 60;
    
    final minController = TextEditingController(text: currentMin.toString());
    final secController = TextEditingController(text: currentSec.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceElevated,
        title: Text('Thiết lập thời gian', style: context.textTheme.headlineMedium),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Phút'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: secController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  int? s = int.tryParse(val);
                  if (s != null && s > 59) {
                    secController.text = '59';
                    secController.selection = TextSelection.fromPosition(const TextPosition(offset: 2));
                  }
                },
                decoration: const InputDecoration(labelText: 'Giây'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
            onPressed: () {
              int m = int.tryParse(minController.text) ?? 0;
              int s = int.tryParse(secController.text) ?? 0;
              setState(() {
                page.duration = (m * 60) + s;
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deletePage(int index) {
    if (_pages.length <= 1) return;
    setState(() {
      final pageId = _pages[index].id;
      _pages.removeAt(index);
      _pageBlocks.remove(pageId);
      if (_selectedPageIndex >= _pages.length) {
        _selectedPageIndex = _pages.length - 1;
      }
    });
  }

  void _showRenamePageDialog(int index) {
    final controller = TextEditingController(text: _pages[index].name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceElevated,
        title: Text('Đổi tên trang', style: context.textTheme.headlineMedium),
        content: TextField(
          controller: controller,
          style: context.textTheme.bodyLarge,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên trang',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _pages[index].name = controller.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockWrapper(StepBlock block, int index, {VoidCallback? onDelete, VoidCallback? onContentChanged, double bottomPadding = 16.0}) {
    return _BlockWrapper(
      key: ValueKey(block.id),
      onDelete: onDelete ?? () => setState(() => _blocks.removeAt(index)),
      bottomPadding: bottomPadding,
      builder: (hovered) => _buildBlockWidget(block, isHovered: hovered, onContentChanged: onContentChanged),
    );
  }

  InputBorder _hoverBorder(bool isHovered) => isHovered
      ? UnderlineInputBorder(
          borderSide: BorderSide(color: context.colors.divider, width: 1),
        )
      : InputBorder.none;

  Widget _buildBlockWidget(StepBlock block, {bool isHovered = false, VoidCallback? onContentChanged}) {
    switch (block.type) {
      case BlockType.heading:
        double defaultSize = 32.0;
        switch (block.headingLevel) {
          case 'h2': defaultSize = 26.0; break;
          case 'h3': defaultSize = 22.0; break;
          case 'h4': defaultSize = 18.0; break;
          case 'h5': defaultSize = 16.0; break;
        }

        final style = context.textTheme.displayLarge!.copyWith(
          fontWeight: (block.isBold ?? true) ? FontWeight.bold : FontWeight.normal,
          fontStyle: (block.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
          decoration: (block.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
          fontSize: block.fontSize ?? defaultSize,
          color: block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null,
        );
        final align = block.textAlign == 'center' ? TextAlign.center : (block.textAlign == 'right' ? TextAlign.right : TextAlign.left);
        return SizedBox(
          height: 60,
          child: TextFormField(
            onTap: () {
              setState(() {
                _focusedStyleBlock = block;
                _onFocusedStyleBlockChanged = () {
                  if (onContentChanged != null) {
                    onContentChanged();
                  } else {
                    setState(() {});
                  }
                };
              });
            },
            initialValue: block.content,
            onChanged: (val) {
              block.content = val;
              onContentChanged?.call();
            },
            style: style,
            textAlign: align,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: _isPreviewMode ? '' : 'Tiêu đề...',
              hintStyle: style.copyWith(color: context.colors.textHint),
              border: InputBorder.none,
              enabledBorder: _hoverBorder(isHovered),
              focusedBorder: _hoverBorder(true),
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );

      case BlockType.text:
        final style = context.textTheme.bodyLarge!.copyWith(
          fontWeight: (block.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
          fontStyle: (block.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
          decoration: (block.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
          fontSize: block.fontSize ?? 16.0,
          color: block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null,
        );
        final align = block.textAlign == 'center' ? TextAlign.center : (block.textAlign == 'right' ? TextAlign.right : TextAlign.left);
        return Container(
          width: double.infinity,
          constraints: _isPreviewMode ? null : const BoxConstraints(minHeight: 120),
          decoration: _isPreviewMode ? null : BoxDecoration(
            border: Border.all(color: context.colors.divider),
            color: context.colors.surface,
          ),
          padding: _isPreviewMode ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextFormField(
            onTap: () {
              setState(() {
                _focusedStyleBlock = block;
                _onFocusedStyleBlockChanged = () {
                  if (onContentChanged != null) {
                    onContentChanged();
                  } else {
                    setState(() {});
                  }
                };
              });
            },
            initialValue: block.content,
            onChanged: (val) {
              block.content = val;
              onContentChanged?.call();
            },
            style: style,
            textAlign: align,
            maxLines: null,
            minLines: _isPreviewMode ? 1 : 5,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: _isPreviewMode ? '' : 'Nhập nội dung đoạn văn...',
              hintStyle: style.copyWith(color: context.colors.textHint),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        );

      case BlockType.image:
        final alignment = block.textAlign == 'center' 
            ? Alignment.center 
            : (block.textAlign == 'right' ? Alignment.centerRight : Alignment.centerLeft);
            
        final imageWidget = Container(
          width: block.width ?? double.infinity,
          height: block.height ?? 200,
          decoration: _isPreviewMode ? null : BoxDecoration(
            border: Border.all(color: context.colors.divider),
          ),
          child: block.content.isEmpty
              ? (_isPreviewMode ? SizedBox.shrink() : Center(child: Icon(Icons.add_photo_alternate_rounded, size: 40, color: context.colors.textHint)))
              : AppImage(imagePath: block.content, fit: BoxFit.cover, width: block.width ?? double.infinity, height: block.height ?? 200),
        );

        return GestureDetector(
          onTap: () {
            if (block.content.isEmpty) {
              _pickSingleImage(block, onContentChanged: onContentChanged);
            }
            setState(() {
              _focusedStyleBlock = block;
              _onFocusedStyleBlockChanged = () {
                if (onContentChanged != null) {
                  onContentChanged();
                } else {
                  setState(() {});
                }
              };
            });
          },
          onDoubleTap: () => _pickSingleImage(block, onContentChanged: onContentChanged),
          onLongPress: () => _pickSingleImage(block, onContentChanged: onContentChanged),
          child: Align(
            alignment: alignment,
            child: imageWidget,
          ),
        );

      case BlockType.images:
        List<dynamic> paths = [];
        try {
          paths = jsonDecode(block.content);
        } catch (_) {}
        
        final alignment = block.textAlign == 'center' 
            ? WrapAlignment.center 
            : (block.textAlign == 'right' ? WrapAlignment.end : WrapAlignment.start);
            
        final imagesWidget = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: _isPreviewMode ? null : BoxDecoration(
            border: Border.all(color: context.colors.divider),
          ),
          child: paths.isEmpty
              ? (_isPreviewMode ? const SizedBox.shrink() : const SizedBox(
                  height: 100,
                  child: Center(child: Text('Nhấn để chọn nhiều ảnh')),
                ))
              : Wrap(
                  alignment: alignment,
                  spacing: 8,
                  runSpacing: 8,
                  children: paths.map((p) => SizedBox(
                    width: block.width ?? 100, height: block.height ?? 100,
                    child: AppImage(imagePath: p.toString(), fit: BoxFit.cover),
                  )).toList(),
                ),
        );

        return GestureDetector(
          onTap: () {
            if (paths.isEmpty) {
              _pickMultipleImages(block, onContentChanged: onContentChanged);
            }
            setState(() {
              _focusedStyleBlock = block;
              _onFocusedStyleBlockChanged = () {
                if (onContentChanged != null) {
                  onContentChanged();
                } else {
                  setState(() {});
                }
              };
            });
          },
          onDoubleTap: () => _pickMultipleImages(block, onContentChanged: onContentChanged),
          onLongPress: () => _pickMultipleImages(block, onContentChanged: onContentChanged),
          child: imagesWidget,
        );

      case BlockType.checkbox:
        final style = context.textTheme.bodyLarge!.copyWith(
          fontWeight: (block.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
          fontStyle: (block.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
          decoration: (block.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
          fontSize: block.fontSize ?? 16.0,
          color: block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null,
        );
        final align = block.textAlign == 'center' ? TextAlign.center : (block.textAlign == 'right' ? TextAlign.right : TextAlign.left);
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20, height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.textSecondary, width: 1.5),
                shape: block.listStyle == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: block.listStyle == 'circle' ? null : BorderRadius.zero,
              ),
            ),
            Expanded(
              child: TextFormField(
                initialValue: block.content,
                onTap: () {
                  setState(() {
                    _focusedStyleBlock = block;
                    _onFocusedStyleBlockChanged = () {
                      if (onContentChanged != null) {
                        onContentChanged();
                      } else {
                        setState(() {});
                      }
                    };
                  });
                },
                onChanged: (val) {
                  block.content = val;
                  onContentChanged?.call();
                },
                style: style,
                textAlign: align,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: _isPreviewMode ? '' : 'Việc cần làm...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  isDense: true,
                ),
              ),
            ),
          ],
        );

      case BlockType.checklist:
        final style = context.textTheme.bodyLarge!.copyWith(
          fontWeight: (block.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
          fontStyle: (block.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
          decoration: (block.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
          fontSize: block.fontSize ?? 16.0,
          color: block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null,
        );
        final align = block.textAlign == 'center' ? TextAlign.center : (block.textAlign == 'right' ? TextAlign.right : TextAlign.left);
        
        List<dynamic> items = [];
        try { items = jsonDecode(block.content); } catch (_) {}
        return Column(
          children: [
            ...items.asMap().entries.map((entry) {
              final _ = entry.key;
              Map<String, dynamic> item = entry.value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 20, height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.textSecondary, width: 1.5),
                      shape: block.listStyle == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: block.listStyle == 'circle' ? null : BorderRadius.zero,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: item['text'],
                      onTap: () {
                        setState(() {
                          _focusedStyleBlock = block;
                          _onFocusedStyleBlockChanged = () {
                            if (onContentChanged != null) {
                              onContentChanged();
                            } else {
                              setState(() {});
                            }
                          };
                        });
                      },
                      onChanged: (val) {
                        item['text'] = val;
                        block.content = jsonEncode(items);
                        onContentChanged?.call();
                      },
                      style: style,
                      textAlign: align,
                      decoration: InputDecoration(
                        hintText: _isPreviewMode ? '' : 'Mục danh sách...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (!_isPreviewMode)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      items.add({"text": "", "checked": false});
                      block.content = jsonEncode(items);
                      onContentChanged?.call();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm mục'),
                ),
              ),
          ],
        );

      case BlockType.ordered:
        final style = context.textTheme.bodyLarge!.copyWith(
          fontWeight: (block.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
          fontStyle: (block.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
          decoration: (block.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
          fontSize: block.fontSize ?? 16.0,
          color: block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null,
        );
        final align = block.textAlign == 'center' ? TextAlign.center : (block.textAlign == 'right' ? TextAlign.right : TextAlign.left);
        
        List<dynamic> orderedItems = [];
        try { orderedItems = jsonDecode(block.content); } catch (_) {}

        String getPrefix(int idx, String? listStyle) {
          if (listStyle == 'bullet') return '•';
          if (listStyle == 'hyphen') return '-';
          if (listStyle == 'roman') {
            const romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV'];
            if (idx < romans.length) return '${romans[idx]}.';
            return '${idx + 1}.';
          }
          return '${idx + 1}.';
        }

        return Column(
          children: [
            ...orderedItems.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> item = Map<String, dynamic>.from(entry.value);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    margin: const EdgeInsets.only(right: 12),
                    alignment: Alignment.center,
                    child: Text(
                      getPrefix(idx, block.listStyle),
                      style: style.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: item['text'],
                      onTap: () {
                        setState(() {
                          _focusedStyleBlock = block;
                          _onFocusedStyleBlockChanged = () {
                            if (onContentChanged != null) {
                              onContentChanged();
                            } else {
                              setState(() {});
                            }
                          };
                        });
                      },
                      onChanged: (val) {
                        orderedItems[idx]['text'] = val;
                        block.content = jsonEncode(orderedItems);
                        onContentChanged?.call();
                      },
                      style: style,
                      textAlign: align,
                      decoration: InputDecoration(
                        hintText: _isPreviewMode ? '' : 'Nội dung mục...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (!_isPreviewMode)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      orderedItems.add({"text": ""});
                      block.content = jsonEncode(orderedItems);
                      onContentChanged?.call();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm mục'),
                ),
              ),
          ],
        );

      case BlockType.column:
        Map<String, dynamic> colData = {'cols': [
          {'blocks': [{'id': const Uuid().v4(), 'type': 'text', 'content': ''}]},
          {'blocks': [{'id': const Uuid().v4(), 'type': 'text', 'content': ''}]},
        ]};
        try {
          final decoded = jsonDecode(block.content);
          if (decoded is Map) colData = Map<String, dynamic>.from(decoded);
        } catch (_) {}

        List<dynamic> cols = List<dynamic>.from(colData['cols'] ?? []);

        void saveColData() {
          block.content = jsonEncode({'cols': cols});
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cols.asMap().entries.map((colEntry) {
            final colIdx = colEntry.key;
            final col = Map<String, dynamic>.from(colEntry.value);
            final subBlocks = List<dynamic>.from(col['blocks'] ?? []);
            final isSelected = _selectedBlockId == block.id && _selectedColIdx == colIdx;
            final isBorderless = block.listStyle == 'borderless';
            final bgColor = block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBlockId = block.id;
                    _selectedColIdx = colIdx;
                    _focusedStyleBlock = block;
                    _onFocusedStyleBlockChanged = () {
                      if (onContentChanged != null) {
                        onContentChanged();
                      } else {
                        setState(() {});
                      }
                    };
                  });
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bgColor ?? (isSelected ? context.colors.primary.withValues(alpha: 0.05) : Colors.transparent),
                    border: isBorderless && !isSelected
                        ? Border.all(color: Colors.transparent, width: 0)
                        : Border(
                            top: BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1),
                            bottom: BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1),
                            left: (colIdx == 0 || isSelected)
                                ? BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1)
                                : BorderSide.none,
                            right: BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: subBlocks.asMap().entries.map((sbEntry) {
                      final sbIdx = sbEntry.key;
                      final sb = Map<String, dynamic>.from(sbEntry.value);
                      final sbTypeStr = sb['type'] as String? ?? 'text';
                      
                      BlockType parsedType = BlockType.values.firstWhere(
                        (e) => e.name == sbTypeStr,
                        orElse: () => BlockType.text
                      );

                      final subBlockObj = StepBlock(
                        id: sb['id'] ?? const Uuid().v4(),
                        type: parsedType,
                        content: sb['content'] ?? '',
                      );

                      return Padding(
                        padding: EdgeInsets.only(bottom: sbIdx < subBlocks.length - 1 ? 8.0 : 0.0),
                        child: _buildBlockWrapper(
                          subBlockObj,
                          sbIdx,
                          bottomPadding: 0.0,
                          onDelete: () {
                            setState(() {
                              subBlocks.removeAt(sbIdx);
                              cols[colIdx]['blocks'] = subBlocks;
                              saveColData();
                            });
                          },
                          onContentChanged: () {
                            subBlocks[sbIdx]['content'] = subBlockObj.content;
                            cols[colIdx]['blocks'] = subBlocks;
                            saveColData();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case BlockType.row:
        Map<String, dynamic> rowData = {'rows': [
          {'blocks': []},
          {'blocks': []},
        ]};
        try {
          final decoded = jsonDecode(block.content);
          if (decoded is Map) rowData = Map<String, dynamic>.from(decoded);
        } catch (_) {}

        List<dynamic> rows = List<dynamic>.from(rowData['rows'] ?? []);

        void saveRowData() {
          block.content = jsonEncode({'rows': rows});
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows.asMap().entries.map((rowEntry) {
            final rowIdx = rowEntry.key;
            final r = Map<String, dynamic>.from(rowEntry.value);
            final subBlocks = List<dynamic>.from(r['blocks'] ?? []);
            final isSelected = _selectedBlockId == block.id && _selectedColIdx == rowIdx;
            final isBorderless = block.listStyle == 'borderless';
            final bgColor = block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBlockId = block.id;
                  _selectedColIdx = rowIdx;
                  _focusedStyleBlock = block;
                  _onFocusedStyleBlockChanged = () {
                    if (onContentChanged != null) {
                      onContentChanged();
                    } else {
                      setState(() {});
                    }
                  };
                });
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor ?? (isSelected ? context.colors.primary.withValues(alpha: 0.05) : Colors.transparent),
                  border: isBorderless && !isSelected
                      ? Border.all(color: Colors.transparent, width: 0)
                      : Border(
                          top: (rowIdx == 0 || isSelected)
                              ? BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1)
                              : BorderSide.none,
                          bottom: BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1),
                          left: BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1),
                          right: BorderSide(color: isSelected ? context.colors.primary : context.colors.divider, width: isSelected ? 1.5 : 1),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: subBlocks.asMap().entries.map((sbEntry) {
                    final sbIdx = sbEntry.key;
                    final sb = Map<String, dynamic>.from(sbEntry.value);
                    final sbTypeStr = sb['type'] as String? ?? 'text';
                    
                    BlockType parsedType = BlockType.values.firstWhere(
                      (e) => e.name == sbTypeStr,
                      orElse: () => BlockType.text
                    );

                    final subBlockObj = StepBlock(
                      id: sb['id'] ?? const Uuid().v4(),
                      type: parsedType,
                      content: sb['content'] ?? '',
                    );

                    return Padding(
                      padding: EdgeInsets.only(bottom: sbIdx < subBlocks.length - 1 ? 8.0 : 0.0),
                      child: _buildBlockWrapper(
                        subBlockObj,
                        sbIdx,
                        bottomPadding: 0.0,
                        onDelete: () {
                          setState(() {
                            subBlocks.removeAt(sbIdx);
                            rows[rowIdx]['blocks'] = subBlocks;
                            saveRowData();
                          });
                        },
                        onContentChanged: () {
                          subBlocks[sbIdx]['content'] = subBlockObj.content;
                          rows[rowIdx]['blocks'] = subBlocks;
                          saveRowData();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        );

      case BlockType.table:
        final style = context.textTheme.bodyMedium!.copyWith(
          fontWeight: (block.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
          fontStyle: (block.isItalic ?? false) ? FontStyle.italic : FontStyle.normal,
          decoration: (block.isUnderline ?? false) ? TextDecoration.underline : TextDecoration.none,
          fontSize: block.fontSize ?? 14.0,
          color: block.color != null ? Color(int.parse(block.color!.replaceFirst('#', '0xFF'))) : null,
        );
        final align = block.textAlign == 'center' ? TextAlign.center : (block.textAlign == 'right' ? TextAlign.right : TextAlign.left);

        List<dynamic> rows = [["", ""], ["", ""]];
        try { rows = jsonDecode(block.content); } catch (_) {}
        return Container(
          decoration: BoxDecoration(border: Border.all(color: context.colors.divider)),
          child: Column(
            children: rows.asMap().entries.map((rowEntry) {
              int rIdx = rowEntry.key;
              List<dynamic> cols = rowEntry.value;
              return Row(
                children: cols.asMap().entries.map((colEntry) {
                  int cIdx = colEntry.key;
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: cIdx < cols.length - 1 ? BorderSide(color: context.colors.divider) : BorderSide.none,
                          bottom: rIdx < rows.length - 1 ? BorderSide(color: context.colors.divider) : BorderSide.none,
                        ),
                      ),
                      child: TextFormField(
                        initialValue: colEntry.value,
                        onTap: () {
                          setState(() {
                            _focusedStyleBlock = block;
                            _onFocusedStyleBlockChanged = () {
                              if (onContentChanged != null) {
                                onContentChanged();
                              } else {
                                setState(() {});
                              }
                            };
                          });
                        },
                        onChanged: (val) {
                          cols[cIdx] = val;
                          block.content = jsonEncode(rows);
                          onContentChanged?.call();
                        },
                        style: style,
                        textAlign: align,
                        decoration: const InputDecoration(border: InputBorder.none, filled: false, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
    }
  }

  Widget _buildToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: context.colors.surfaceElevated,
      child: Row(
        children: [
          Expanded(child: _toolbarMenu(
            label: 'Văn bản',
            items: const [
              PopupMenuItem(value: 'heading', child: Text('Tiêu đề')),
              PopupMenuItem(value: 'p', child: Text('Đoạn văn')),
            ],
          )),
          _toolbarDivider(),
          Expanded(child: _toolbarMenu(
            label: 'Truyền thông',
            items: const [
              PopupMenuItem(value: 'img', child: Text('Ảnh')),
              PopupMenuItem(value: 'imgs', child: Text('Nhiều ảnh')),
            ],
          )),
          _toolbarDivider(),
          Expanded(child: _toolbarMenu(
            label: 'Danh sách',
            items: const [
              PopupMenuItem(value: 'checkbox', child: Text('Checkbox')),
              PopupMenuItem(value: 'checklist', child: Text('Checklist')),
              PopupMenuItem(value: 'ordered', child: Text('Số thứ tự')),
            ],
          )),
          _toolbarDivider(),
          Expanded(child: _toolbarMenu(
            label: 'Bố cục',
            items: const [
              PopupMenuItem(value: 'col', child: Text('Cột')),
              PopupMenuItem(value: 'row', child: Text('Hàng')),
              PopupMenuItem(value: 'table', child: Text('Bảng')),
            ],
          )),
        ],
      ),
    );
  }

  Widget _toolbarDivider() => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: context.colors.divider,
  );

  Widget _toolbarMenu({
    required String label,
    required List<PopupMenuEntry<String>> items,
  }) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 36),
      onSelected: _addBlock,
      itemBuilder: (context) => items,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: context.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget bọc mỗi block — hiển thị viền khi hover, nút xoá khi hover
class _BlockWrapper extends StatefulWidget {
  final Widget Function(bool hovered) builder;
  final VoidCallback onDelete;
  final double bottomPadding;

  const _BlockWrapper({
    required super.key,
    required this.builder,
    required this.onDelete,
    this.bottomPadding = 16.0,
  });

  @override
  State<_BlockWrapper> createState() => _BlockWrapperState();
}

class _BlockWrapperState extends State<_BlockWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.builder(_hovered),
            if (_hovered)
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: context.colors.surfaceElevated,
                    child: Icon(Icons.close, size: 14, color: context.colors.textHint),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StyleEditorPanel extends StatefulWidget {
  final StepBlock block;
  final ScrollController scrollController;
  final VoidCallback onStyleChanged;
  final VoidCallback? onHandleTapped;
  final VoidCallback? onPickImage;

  const _StyleEditorPanel({
    required this.block,
    required this.scrollController,
    required this.onStyleChanged,
    this.onHandleTapped,
    this.onPickImage,
  });

  @override
  State<_StyleEditorPanel> createState() => _StyleEditorPanelState();
}

class _StyleEditorPanelState extends State<_StyleEditorPanel> {
  late TextEditingController _fontSizeController;
  late TextEditingController _colorController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    final initialFontSize = widget.block.fontSize ?? (widget.block.type == BlockType.heading ? _getDefaultHeadingSize(widget.block.headingLevel) : 16.0);
    _fontSizeController = TextEditingController(text: initialFontSize.round().toString());
    _colorController = TextEditingController(text: widget.block.color ?? '');
    _widthController = TextEditingController(text: widget.block.width != null ? widget.block.width!.round().toString() : '');
    _heightController = TextEditingController(text: widget.block.height != null ? widget.block.height!.round().toString() : '');
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _colorController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateStyle(void Function() update) {
    setState(update);
    widget.onStyleChanged();
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        GestureDetector(
          onTap: widget.onHandleTapped,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 8),
                Text('Chạm hoặc vuốt để định dạng', style: context.textTheme.bodySmall!.copyWith(color: context.colors.textHint)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          (block.type == BlockType.image || block.type == BlockType.images) ? 'Định dạng hình ảnh' : 'Định dạng văn bản', 
          style: context.textTheme.headlineMedium
        ),
        const SizedBox(height: 24),
        
        if (block.type == BlockType.image || block.type == BlockType.images) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chiều rộng (px)', style: context.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      decoration: const InputDecoration(suffixText: 'px'),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        _updateStyle(() => block.width = parsed);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chiều cao (px)', style: context.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      decoration: const InputDecoration(suffixText: 'px'),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        _updateStyle(() => block.height = parsed);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Thay đổi / Chọn ảnh'),
              onPressed: widget.onPickImage,
            ),
          ),
          const SizedBox(height: 16),
          Text('Căn lề', style: context.textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _formatToggle(
                icon: Icons.format_align_left,
                isActive: (block.textAlign ?? 'left') == 'left',
                onTap: () => _updateStyle(() => block.textAlign = 'left'),
              ),
              const SizedBox(width: 8),
              _formatToggle(
                icon: Icons.format_align_center,
                isActive: block.textAlign == 'center',
                onTap: () => _updateStyle(() => block.textAlign = 'center'),
              ),
              const SizedBox(width: 8),
              _formatToggle(
                icon: Icons.format_align_right,
                isActive: block.textAlign == 'right',
                onTap: () => _updateStyle(() => block.textAlign = 'right'),
              ),
            ],
          ),
        ],
        if (block.type == BlockType.column || block.type == BlockType.row) ...[
          Text('Định dạng Bố cục', style: context.textTheme.headlineMedium),
          const SizedBox(height: 24),
          
          Text('Khung viền', style: context.textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _listStyleButton('Có viền', 'bordered', icon: Icons.border_all),
              const SizedBox(width: 8),
              _listStyleButton('Không viền', 'borderless', icon: Icons.border_clear),
            ],
          ),
          const SizedBox(height: 16),
          
          Text('Màu nền', style: context.textTheme.labelMedium),
          const SizedBox(height: 8),
          _buildColorPicker(),
        ],
        if (block.type != BlockType.image && block.type != BlockType.images && block.type != BlockType.column && block.type != BlockType.row) ...[
        if (block.type == BlockType.checkbox || block.type == BlockType.checklist) ...[
          Text('Kiểu Checkbox', style: context.textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _listStyleButton('Vuông', 'square', icon: Icons.check_box_outline_blank),
              const SizedBox(width: 8),
              _listStyleButton('Tròn', 'circle', icon: Icons.radio_button_unchecked),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (block.type == BlockType.ordered) ...[
          Text('Kiểu Đánh số', style: context.textTheme.labelMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _listStyleButton('Số', 'number'),
                const SizedBox(width: 8),
                _listStyleButton('La Mã', 'roman'),
                const SizedBox(width: 8),
                _listStyleButton('Chấm (•)', 'bullet'),
                const SizedBox(width: 8),
                _listStyleButton('Gạch (-)', 'hyphen'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (block.type == BlockType.heading) ...[
          Text('Cấp độ tiêu đề', style: context.textTheme.labelMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _headingLevelButton('H1', 'h1'),
                const SizedBox(width: 8),
                _headingLevelButton('H2', 'h2'),
                const SizedBox(width: 8),
                _headingLevelButton('H3', 'h3'),
                const SizedBox(width: 8),
                _headingLevelButton('H4', 'h4'),
                const SizedBox(width: 8),
                _headingLevelButton('H5', 'h5'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text('Kích thước chữ', style: context.textTheme.labelMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: _fontSizeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              suffixText: 'px',
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed > 0) {
                _updateStyle(() => block.fontSize = parsed);
              } else if (val.isEmpty) {
                // Allows clearing the input without breaking
              }
            },
          ),
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kiểu chữ', style: context.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _formatToggle(
                        icon: Icons.format_bold,
                        isActive: block.isBold ?? (block.type == BlockType.heading ? true : false),
                        onTap: () => _updateStyle(() => block.isBold = !(block.isBold ?? (block.type == BlockType.heading ? true : false))),
                      ),
                      const SizedBox(width: 8),
                      _formatToggle(
                        icon: Icons.format_italic,
                        isActive: block.isItalic ?? false,
                        onTap: () => _updateStyle(() => block.isItalic = !(block.isItalic ?? false)),
                      ),
                      const SizedBox(width: 8),
                      _formatToggle(
                        icon: Icons.format_underlined,
                        isActive: block.isUnderline ?? false,
                        onTap: () => _updateStyle(() => block.isUnderline = !(block.isUnderline ?? false)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Căn lề', style: context.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _formatToggle(
                        icon: Icons.format_align_left,
                        isActive: (block.textAlign ?? 'left') == 'left',
                        onTap: () => _updateStyle(() => block.textAlign = 'left'),
                      ),
                      const SizedBox(width: 8),
                      _formatToggle(
                        icon: Icons.format_align_center,
                        isActive: block.textAlign == 'center',
                        onTap: () => _updateStyle(() => block.textAlign = 'center'),
                      ),
                      const SizedBox(width: 8),
                      _formatToggle(
                        icon: Icons.format_align_right,
                        isActive: block.textAlign == 'right',
                        onTap: () => _updateStyle(() => block.textAlign = 'right'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        Text('Màu sắc', style: context.textTheme.labelMedium),
        const SizedBox(height: 8),
        _buildColorPicker(),
        ],
      ],
    );
  }

  Widget _buildColorPicker() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _colorDot(null, context.colors.textPrimary),
            _colorDot('#FF3B30', const Color(0xFFFF3B30)),
            _colorDot('#34C759', const Color(0xFF34C759)),
            _colorDot('#007AFF', const Color(0xFF007AFF)),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.divider),
              gradient: const SweepGradient(
                colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                hintText: 'VD: #FF0000',
                prefixIcon: Icon(Icons.color_lens, size: 18),
              ),
              onChanged: (val) {
                if (val.isEmpty) {
                  _updateStyle(() => widget.block.color = null);
                  return;
                }
                String hex = val.toUpperCase();
                if (!hex.startsWith('#')) hex = '#$hex';
                if (hex.length == 7 || hex.length == 9) {
                  final isValid = RegExp(r'^#[0-9A-F]+$').hasMatch(hex);
                  if (isValid) {
                    _updateStyle(() => widget.block.color = hex);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _formatToggle({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? context.colors.primary : context.colors.divider),
        ),
        child: Icon(icon, size: 20, color: isActive ? context.colors.primary : context.colors.textPrimary),
      ),
    );
  }

  Widget _colorDot(String? hex, Color color) {
    final isActive = widget.block.color == hex;
    return GestureDetector(
      onTap: () {
        _updateStyle(() => widget.block.color = hex);
        _colorController.text = hex ?? '';
      },
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? context.colors.primary : context.colors.divider, width: isActive ? 2 : 1),
        ),
      ),
    );
  }

  void _showColorPicker() {
    Color pickerColor = widget.block.color != null && RegExp(r'^#[0-9A-F]{6}$').hasMatch(widget.block.color!)
        ? Color(int.parse(widget.block.color!.replaceFirst('#', '0xFF'))) 
        : context.colors.background;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.surfaceElevated,
          title: Text('Chọn màu sắc', style: context.textTheme.headlineMedium),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
                final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                _updateStyle(() => widget.block.color = hex);
                _colorController.text = hex;
              },
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [],
              colorPickerWidth: 280,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Xong'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double _getDefaultHeadingSize(String? level) {
    switch (level) {
      case 'h1': return 32.0;
      case 'h2': return 26.0;
      case 'h3': return 22.0;
      case 'h4': return 18.0;
      case 'h5': return 16.0;
      default: return 32.0;
    }
  }

  Widget _headingLevelButton(String label, String value) {
    final isLevelMatch = (widget.block.headingLevel ?? 'h1') == value;
    final isSizeMatch = widget.block.fontSize == null || widget.block.fontSize == _getDefaultHeadingSize(widget.block.headingLevel ?? 'h1');
    final isActive = isLevelMatch && isSizeMatch;
    return GestureDetector(
      onTap: () {
        _updateStyle(() {
          widget.block.headingLevel = value;
          // Xoá fontSize custom để nó tự nhận size mặc định của H mới
          widget.block.fontSize = null;
        });
        _fontSizeController.text = _getDefaultHeadingSize(value).round().toString();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? context.colors.primary : context.colors.divider),
        ),
        child: Text(label, style: TextStyle(color: isActive ? context.colors.primary : context.colors.textPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _listStyleButton(String label, String value, {IconData? icon}) {
    final isActive = widget.block.listStyle == value || (widget.block.listStyle == null && (value == 'square' || value == 'number'));
    return GestureDetector(
      onTap: () {
        _updateStyle(() {
          widget.block.listStyle = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? context.colors.primary : context.colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isActive ? context.colors.primary : context.colors.textPrimary),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(color: isActive ? context.colors.primary : context.colors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
