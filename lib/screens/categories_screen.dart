import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const List<String> _categories = [
    'Chiên', 'Xào', 'Luộc', 'Hấp', 'Hầm', 'Kho', 'Nướng', 'Nấu', 'Khác'
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Chiên': Icons.local_fire_department_rounded,
    'Xào': Icons.whatshot_rounded,
    'Luộc': Icons.water_drop_rounded,
    'Hấp': Icons.cloud_rounded,
    'Hầm': Icons.soup_kitchen_rounded,
    'Kho': Icons.kitchen_rounded,
    'Nướng': Icons.outdoor_grill_rounded,
    'Nấu': Icons.restaurant_rounded,
    'Khác': Icons.more_horiz_rounded,
  };

  String? _selectedCategory;

  List<Recipe> _filtered(List<Recipe> all) {
    if (_selectedCategory == null) return all;
    return all.where((r) => r.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildCategoryChips(context),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  final filtered = _filtered(provider.recipes.toList());
                  if (filtered.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final recipe = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecipeCard(
                          recipe: recipe,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân loại',
            style: context.textTheme.displayMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Khám phá công thức theo phương pháp nấu',
            style: context.textTheme.bodyMedium!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // All chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tất cả'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
              selectedColor: context.colors.primary.withValues(alpha: 0.15),
              checkmarkColor: context.colors.primary,
              labelStyle: TextStyle(
                color: _selectedCategory == null
                    ? context.colors.primary
                    : context.colors.textSecondary,
                fontWeight: _selectedCategory == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              backgroundColor: context.colors.surfaceElevated,
              side: BorderSide(
                color: _selectedCategory == null
                    ? context.colors.primary
                    : context.colors.divider,
              ),
            ),
          ),
          ..._categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  _categoryIcons[cat] ?? Icons.more_horiz_rounded,
                  size: 16,
                  color: isSelected ? context.colors.primary : context.colors.textSecondary,
                ),
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
                selectedColor: context.colors.primary.withValues(alpha: 0.15),
                checkmarkColor: context.colors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? context.colors.primary : context.colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: context.colors.surfaceElevated,
                side: BorderSide(
                  color: isSelected ? context.colors.primary : context.colors.divider,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedCategory != null
                  ? (_categoryIcons[_selectedCategory!] ?? Icons.more_horiz_rounded)
                  : Icons.restaurant_menu_rounded,
              size: 40,
              color: context.colors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory != null
                ? 'Chưa có công thức "$_selectedCategory"'
                : 'Chưa có công thức nào',
            style: context.textTheme.headlineSmall!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm công thức từ trang chủ và gán loại để hiển thị ở đây.',
            style: context.textTheme.bodySmall!.copyWith(
              color: context.colors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
