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
  bool _imageError = false; // true khi người dùng cố lưu mà chưa chọn ảnh
  int _difficulty = 0;
  bool _isSaving = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _imagePath = r?.imagePath;
    _difficulty = r?.difficulty ?? 0;
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

  Future<void> _saveAndContinue() async {
    final formValid = _formKey.currentState!.validate();
    // Validate ảnh bắt buộc
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    setState(() => _imageError = !hasImage);
    if (!formValid || !hasImage) return;
    setState(() => _isSaving = true);

    Recipe recipeToEdit;

    if (_isEditing) {
      recipeToEdit = widget.recipe!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        imagePath: _imagePath,
        clearImage: _imagePath == null,
        difficulty: _difficulty,
      );
    } else {
      recipeToEdit = Recipe(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        imagePath: _imagePath,
        difficulty: _difficulty,
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
            // Image picker (bắt buộc *)
            Row(
              children: [
                Text('Ảnh món ăn', style: context.textTheme.headlineSmall),
                const SizedBox(width: 4),
                Text('*', style: context.textTheme.headlineSmall!.copyWith(color: context.colors.error)),
              ],
            ),
            const SizedBox(height: 8),
            _buildImagePicker(),
            if (_imageError) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: context.colors.error),
                  const SizedBox(width: 6),
                  Text(
                    'Vui lòng chọn ảnh đại diện cho món ăn',
                    style: context.textTheme.bodySmall!.copyWith(color: context.colors.error),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Name
            Text('Tên món ăn *', style: context.textTheme.headlineSmall),
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

            // Difficulty
            Text('Mức độ khó', style: context.textTheme.headlineSmall),
            const SizedBox(height: 12),
            _buildDifficultySelector(),
            const SizedBox(height: 24),

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
    final borderColor = _imageError
        ? context.colors.error
        : _imagePath != null
            ? context.colors.primary
            : context.colors.divider;
    final borderWidth = (_imageError || _imagePath != null) ? 1.5 : 1.0;

    return GestureDetector(
      onTap: () {
        _pickImage();
        // Xoá lỗi khi người dùng nhấn vào vùng chọn ảnh
        if (_imageError) setState(() => _imageError = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _imageError
              ? context.colors.error.withValues(alpha: 0.04)
              : context.colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _imageError
                          ? context.colors.error.withValues(alpha: 0.1)
                          : context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _imageError
                          ? Icons.broken_image_outlined
                          : Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: _imageError ? context.colors.error : context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _imageError ? 'Bắt buộc phải chọn ảnh' : 'Thêm ảnh món ăn',
                    style: context.textTheme.labelLarge!.copyWith(
                      color: _imageError ? context.colors.error : context.colors.textSecondary,
                      fontWeight: _imageError ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (_imageError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Nhấn để chọn ảnh từ thư viện',
                      style: context.textTheme.bodySmall!.copyWith(
                        color: context.colors.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return SegmentedButton<int>(
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
}
