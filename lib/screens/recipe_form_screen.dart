import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_image.dart';
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
  late TextEditingController _descController;
  String? _imagePath;
  int _difficulty = 0;
  String? _estimatedTime;
  String? _category;
  List<String> _descriptionImages = [];
  int _selectedDescriptionImageIndex = 0;
  bool _isSaving = false;
  bool _showDescImagesError = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _imagePath = r?.imagePath;
    _difficulty = r?.difficulty ?? 0;
    _estimatedTime = r?.estimatedTime;
    _category = r?.category;
    _descriptionImages = r?.descriptionImages != null ? List.from(r!.descriptionImages) : [];
  }

  @override
  void dispose() {
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
        _selectedDescriptionImageIndex = _descriptionImages.length - pickedFiles.length; // Select the first newly added image
        _showDescImagesError = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final formValid = _formKey.currentState!.validate();
    if (_descriptionImages.isEmpty) {
      setState(() => _showDescImagesError = true);
    }
    if (!formValid || _descriptionImages.isEmpty) return;
    setState(() => _isSaving = true);

    Recipe recipeToEdit;

    if (_isEditing) {
      recipeToEdit = widget.recipe!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        imagePath: _imagePath,
        clearImage: _imagePath == null,
        difficulty: _difficulty,
        estimatedTime: _estimatedTime,
        category: _category,
        descriptionImages: _descriptionImages,
      );
    } else {
      recipeToEdit = Recipe(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        imagePath: _imagePath,
        difficulty: _difficulty,
        estimatedTime: _estimatedTime,
        category: _category,
        descriptionImages: _descriptionImages,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      // Chuyển tiếp sang trang Edit (không dùng replacement để có thể back lại)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeEditorScreen(recipe: recipeToEdit),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(24),
          children: [
            // Name
            Text('Tên món ăn', style: context.textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: context.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Phở bò, Cơm chiên...',
                hintStyle: TextStyle(color: context.colors.textHint),
                filled: true,
                fillColor: context.colors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên món' : null,
            ),
            const SizedBox(height: 24),

            // Image picker
            Text('Ảnh món ăn', style: context.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildImagePicker(),
            ),
            const SizedBox(height: 32),

            // Category
            Text('Loại món ăn', style: context.textTheme.headlineSmall),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Difficulty
            Text('Độ khó', style: context.textTheme.headlineSmall),
            const SizedBox(height: 12),
            _buildDifficultySelector(),
            const SizedBox(height: 24),

            // Estimated Time
            Text('Thời gian ước tính', style: context.textTheme.headlineSmall),
            const SizedBox(height: 12),
            _buildEstimatedTimeSelector(),
            const SizedBox(height: 24),

            // Description images
            Text('Ảnh mô tả', style: context.textTheme.headlineSmall),
            const SizedBox(height: 8),
            _buildDescriptionImagesSection(),
            const SizedBox(height: 32),

            // Description
            Text('Mô tả', style: context.textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style: context.textTheme.bodyMedium,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mô tả ngắn về món ăn này...',
                hintStyle: TextStyle(color: context.colors.textHint),
                filled: true,
                fillColor: context.colors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Start / Save button
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 220,
        width: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(imagePath: _imagePath, fit: BoxFit.cover),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : const AppImagePlaceholder(text: 'Chưa chọn ảnh món ăn'),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('Dễ'),
          icon: Icon(Icons.sentiment_satisfied_rounded),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Trung bình'),
          icon: Icon(Icons.sentiment_neutral_rounded),
        ),
        ButtonSegment(
          value: 2,
          label: Text('Khó'),
          icon: Icon(Icons.local_fire_department_rounded),
        ),
      ],
      selected: {_difficulty},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _difficulty = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: context.colors.surfaceElevated,
        selectedBackgroundColor: context.colors.primary.withValues(alpha: 0.15),
        selectedForegroundColor: context.colors.primary,
        foregroundColor: context.colors.textSecondary,
        side: BorderSide(color: context.colors.divider),
      ),
    );
  }

  Widget _buildEstimatedTimeSelector() {
    final times = ['<5p', '<10p', '<15p', '<20p', '<30p', '>30p'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            final selected = _estimatedTime == time;
            return SizedBox(
              width: itemWidth,
              child: ChoiceChip(
                label: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text(time),
                ),
                showCheckmark: false,
                labelPadding: EdgeInsets.zero,
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    _estimatedTime = val ? time : null;
                  });
                },
                selectedColor: context.colors.primary.withValues(alpha: 0.15),
                backgroundColor: context.colors.surfaceElevated,
                labelStyle: TextStyle(
                  color: selected ? context.colors.primary : context.colors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? context.colors.primary : context.colors.divider,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      'Chiên', 'Xào', 'Luộc', 'Hấp', 'Hầm', 'Kho', 'Nướng', 'Nấu', 'Nước', 'Khác'
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _category == cat;
        return ChoiceChip(
          label: Text(cat),
          showCheckmark: false,
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _category = selected ? cat : null;
            });
          },
          selectedColor: context.colors.primary.withValues(alpha: 0.2),
          backgroundColor: context.colors.surfaceElevated,
          labelStyle: context.textTheme.bodyMedium!.copyWith(
            color: isSelected ? context.colors.primary : context.colors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: isSelected 
              ? BorderSide(color: context.colors.primary) 
              : BorderSide(color: context.colors.divider),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large image preview
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: _showDescImagesError
                    ? Border.all(color: context.colors.error, width: 2)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: _descriptionImages.isNotEmpty
                  ? AppImage(
                      imagePath: _descriptionImages[_selectedDescriptionImageIndex],
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
                        _selectedDescriptionImageIndex = _selectedDescriptionImageIndex.clamp(0, _descriptionImages.length - 1);
                      } else {
                        _selectedDescriptionImageIndex = 0;
                        _showDescImagesError = true;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        if (_showDescImagesError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              'Vui lòng chọn ít nhất một ảnh mô tả',
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Horizontal list of thumbnails
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _descriptionImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _descriptionImages.length) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return GestureDetector(
                  onTap: _pickDescriptionImages,
                  child: Container(
                    width: 80,
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
                          size: 24, color: isDark ? Colors.grey[600] : Colors.grey[450]),
                    ),
                  ),
                );
              }
              final path = _descriptionImages[index];
              final isSelected = index == _selectedDescriptionImageIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDescriptionImageIndex = index),
                child: Container(
                  width: 80,
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
