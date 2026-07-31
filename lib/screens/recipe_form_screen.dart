import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_image.dart';
import '../widgets/rich_text_controller.dart';
import 'recipe_editor_screen.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late RichTextEditingController _descController;
  String? _imagePath;
  int? _difficulty;
  String? _estimatedTime;
  String? _category;
  List<String> _descriptionImages = [];
  int _selectedDescriptionImageIndex = 0;
  bool _isSaving = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = RichTextEditingController(initialHtml: r?.description ?? '');
    _descController.addListener(_onControllerStateChanged);
    _imagePath = r?.imagePath;
    _difficulty = r?.difficulty;
    _estimatedTime = r?.estimatedTime;
    _category = r?.category;
    _descriptionImages = r?.descriptionImages != null ? List.from(r!.descriptionImages) : [];
  }

  void _onControllerStateChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _descController.removeListener(_onControllerStateChanged);
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _pickDescriptionImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _descriptionImages.addAll(pickedFiles.map((e) => e.path));
        if (_descriptionImages.isNotEmpty) {
          _selectedDescriptionImageIndex = _descriptionImages.length - 1;
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;
    setState(() => _isSaving = true);

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final existingNames = recipeProvider.recipes
        .where((r) => r.id != widget.recipe?.id)
        .map((r) => r.name.trim().toLowerCase())
        .toSet();

    // Default Name: Món 1, Món 2... ensure no duplicate
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      int index = 1;
      while (existingNames.contains('món $index')) {
        index++;
      }
      name = 'Món $index';
    }

    // Default Description: 'chưa có mô tả'
    String description = _descController.toFormattedString().trim();
    if (description.isEmpty) {
      description = 'chưa có mô tả';
    }

    // Default Category: 'khác'
    String category = (_category == null || _category!.trim().isEmpty) ? 'khác' : _category!;

    // Default Time: '5p'
    String estimatedTime = (_estimatedTime == null || _estimatedTime!.trim().isEmpty) ? '5p' : _estimatedTime!;

    // Default Difficulty: 0 (dễ)
    int difficulty = _difficulty ?? 0;

    Recipe recipeToEdit;

    if (_isEditing) {
      recipeToEdit = widget.recipe!.copyWith(
        name: name,
        description: description,
        imagePath: _imagePath,
        clearImage: _imagePath == null,
        difficulty: difficulty,
        estimatedTime: estimatedTime,
        category: category,
        descriptionImages: _descriptionImages,
      );
    } else {
      recipeToEdit = Recipe(
        id: const Uuid().v4(),
        name: name,
        description: description,
        imagePath: _imagePath,
        difficulty: difficulty,
        estimatedTime: estimatedTime,
        category: category,
        descriptionImages: _descriptionImages,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeEditorScreen(recipe: recipeToEdit),
        ),
      );
    }
  }

  Widget _buildFormattingToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border(
          bottom: BorderSide(color: context.colors.divider.withValues(alpha: 0.6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'In đậm (B)',
              isActive: _descController.activeStyle.bold,
              onPressed: () => _descController.toggleBold(),
            ),
            _buildToolbarButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'In nghiêng (I)',
              isActive: _descController.activeStyle.italic,
              onPressed: () => _descController.toggleItalic(),
            ),
            _buildToolbarButton(
              icon: Icons.format_underlined_rounded,
              tooltip: 'Gạch chân (U)',
              isActive: _descController.activeStyle.underline,
              onPressed: () => _descController.toggleUnderline(),
            ),
            _buildToolbarButton(
              icon: Icons.strikethrough_s_rounded,
              tooltip: 'Gạch ngang (S)',
              isActive: _descController.activeStyle.strikethrough,
              onPressed: () => _descController.toggleStrikethrough(),
            ),
            Container(
              height: 18,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: context.colors.divider,
            ),
            _buildToolbarButton(
              icon: Icons.format_clear_rounded,
              tooltip: 'Xóa định dạng',
              isActive: false,
              onPressed: () => _descController.clearFormatting(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          color: isActive ? Colors.white : context.colors.textPrimary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: 0,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Dễ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1),
            ),
            icon: Icon(Icons.sentiment_satisfied_rounded, size: 18),
          ),
          ButtonSegment(
            value: 1,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Trung bình', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1),
            ),
            icon: Icon(Icons.sentiment_neutral_rounded, size: 18),
          ),
          ButtonSegment(
            value: 2,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Khó', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1),
            ),
            icon: Icon(Icons.local_fire_department_rounded, size: 18),
          ),
        ],
        selected: _difficulty != null ? {_difficulty!} : <int>{},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            _difficulty = newSelection.isNotEmpty ? newSelection.first : null;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return context.colors.primary.withValues(alpha: 0.15);
            }
            return context.colors.surfaceElevated;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return context.colors.primary;
            }
            return context.colors.textSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide(color: context.colors.divider)),
        ),
      ),
    );
  }

  Widget _buildTwoColumnDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    final List<List<String>> pairs = [];
    for (int i = 0; i < items.length; i += 2) {
      pairs.add([
        items[i],
        if (i + 1 < items.length) items[i + 1],
      ]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: PopupMenuButton<String>(
            tooltip: '',
            borderRadius: BorderRadius.circular(10),
            offset: const Offset(0, 48),
            constraints: BoxConstraints(minWidth: boxWidth, maxWidth: boxWidth),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.colors.surfaceElevated,
          elevation: 6,
          onSelected: onSelected,
          itemBuilder: (context) {
            return [
              PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: boxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: pairs.map((pair) {
                      final leftItem = pair[0];
                      final rightItem = pair.length > 1 ? pair[1] : null;

                      return Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pop(context, leftItem),
                              child: _buildListItemCell(leftItem, isSelected: value == leftItem),
                            ),
                          ),
                          Expanded(
                            child: rightItem != null
                                ? InkWell(
                                    onTap: () => Navigator.pop(context, rightItem),
                                    child: _buildListItemCell(rightItem, isSelected: value == rightItem),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ];
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue ? context.colors.primary.withValues(alpha: 0.5) : context.colors.divider,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasValue ? context.colors.textPrimary : context.colors.textHint,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasValue ? context.colors.primary : context.colors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildListItemCell(String text, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? context.colors.primary : context.colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 15,
                color: context.colors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Chiên', 'Xào', 'Luộc', 'Hấp', 'Hầm', 'Kho', 'Nướng', 'Nấu', 'Nước', 'Khác'
    ];
    final times = ['5p', '<10p', '<15p', '<20p', '<30p', '>30p'];

    final titleStyle = context.textTheme.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thông tin chung' : 'Thêm công thức mới'),
        backgroundColor: context.colors.background,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── 1. Tên món ăn ───
            Text('Tên món ăn', style: titleStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: context.textTheme.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Phở bò, Cơm chiên...',
                hintStyle: TextStyle(color: context.colors.textHint, fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: context.colors.surfaceElevated,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final trimmed = v?.trim() ?? '';
                if (trimmed.isNotEmpty) {
                  final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
                  final existingNames = recipeProvider.recipes
                      .where((r) => r.id != widget.recipe?.id)
                      .map((r) => r.name.trim().toLowerCase())
                      .toSet();
                  if (existingNames.contains(trimmed.toLowerCase())) {
                    return 'Tên món ăn đã tồn tại';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // ─── 2. Avatar (Trái) & Loại món + Thời gian (Phải) ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar (Left)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ảnh món ăn', style: titleStyle),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 130,
                        width: 130,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: context.colors.surfaceElevated,
                        ),
                        child: _imagePath != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppImage(imagePath: _imagePath, fit: BoxFit.cover),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _imagePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const AppImagePlaceholder(text: 'Chọn ảnh món', width: 130, height: 130),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Category & Time (Right)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loại món ăn', style: titleStyle),
                      const SizedBox(height: 8),
                      _buildTwoColumnDropdown(
                        value: _category,
                        hint: 'Chọn loại món',
                        items: categories,
                        onSelected: (val) => setState(() => _category = val),
                      ),
                      const SizedBox(height: 12),
                      Text('Thời gian ước tính', style: titleStyle),
                      const SizedBox(height: 8),
                      _buildTwoColumnDropdown(
                        value: _estimatedTime,
                        hint: 'Chọn thời gian',
                        items: times,
                        onSelected: (val) => setState(() => _estimatedTime = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ─── 3. Độ khó ───
            Text('Độ khó', style: titleStyle),
            const SizedBox(height: 8),
            _buildDifficultySelector(),

            const SizedBox(height: 20),

            // ─── 4. Ảnh mô tả ───
            Text('Ảnh mô tả', style: titleStyle),
            const SizedBox(height: 8),
            _buildDescriptionImagesSection(),

            const SizedBox(height: 20),

            // ─── 5. Mô tả ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mô tả', style: titleStyle),
                Text(
                  'Định dạng cơ bản',
                  style: TextStyle(fontSize: 11, color: context.colors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildFormattingToolbar(),
                  TextFormField(
                    controller: _descController,
                    style: context.textTheme.bodyMedium,
                    minLines: 8,
                    maxLines: 15,
                    decoration: InputDecoration(
                      hintText: 'Mô tả ngắn về món ăn này...',
                      hintStyle: TextStyle(color: context.colors.textHint, fontSize: 13),
                      contentPadding: const EdgeInsets.all(12),
                      filled: true,
                      fillColor: context.colors.surfaceElevated,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Save / Start Button ───
            ElevatedButton(
              onPressed: _isSaving ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Lưu thông tin' : 'Bắt đầu',
                      style: context.textTheme.labelLarge!.copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large image preview
        GestureDetector(
          onTap: _descriptionImages.isEmpty ? _pickDescriptionImages : null,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _descriptionImages.isNotEmpty
                    ? AppImage(
                        imagePath: _descriptionImages[_selectedDescriptionImageIndex.clamp(0, _descriptionImages.length - 1)],
                        fit: BoxFit.cover,
                      )
                    : const AppImagePlaceholder(text: 'Chưa có ảnh mô tả'),
              ),
              if (_descriptionImages.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _descriptionImages.removeAt(_selectedDescriptionImageIndex);
                        if (_descriptionImages.isNotEmpty) {
                          _selectedDescriptionImageIndex =
                              _selectedDescriptionImageIndex.clamp(0, _descriptionImages.length - 1);
                        } else {
                          _selectedDescriptionImageIndex = 0;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Horizontal list of thumbnails
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _descriptionImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _descriptionImages.length) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return GestureDetector(
                  onTap: _pickDescriptionImages,
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.add_photo_alternate_rounded,
                          size: 22, color: isDark ? Colors.grey[600] : Colors.grey[450]),
                    ),
                  ),
                );
              }
              final path = _descriptionImages[index];
              final isSelected = index == _selectedDescriptionImageIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDescriptionImageIndex = index),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? context.colors.primary : context.colors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppImage(
                    imagePath: path,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
