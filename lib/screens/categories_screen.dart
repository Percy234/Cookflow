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
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Chiên', 'icon': Icons.local_fire_department_rounded},
    {'name': 'Xào', 'icon': Icons.whatshot_rounded},
    {'name': 'Luộc', 'icon': Icons.water_drop_rounded},
    {'name': 'Hấp', 'icon': Icons.cloud_rounded},
    {'name': 'Hầm', 'icon': Icons.soup_kitchen_rounded},
    {'name': 'Kho', 'icon': Icons.set_meal_rounded},
    {'name': 'Nướng', 'icon': Icons.outdoor_grill_rounded},
    {'name': 'Nấu', 'icon': Icons.restaurant_rounded},
    {'name': 'Nước', 'icon': Icons.local_drink_rounded},
    {'name': 'Khác', 'icon': Icons.more_horiz_rounded},
  ];

  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filtered(List<Recipe> all) {
    List<Recipe> result = all;
    if (_selectedCategory != null) {
      result = result
          .where((r) => (r.category ?? '') == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((r) =>
              (r.name ?? '').toLowerCase().contains(_searchQuery))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Consumer<RecipeProvider>(
          builder: (context, provider, _) {
            final allRecipes = provider.recipes.toList();
            final filtered = _filtered(allRecipes);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Search bar ──────────────────────────────────────────
                SliverToBoxAdapter(child: _buildSearchBar(context)),

                // ── Category icon grid ──────────────────────────────────
                SliverToBoxAdapter(child: _buildCategoryGrid(context)),

                // ── Section label ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _selectedCategory != null
                              ? _selectedCategory!
                              : 'Tất cả công thức',
                          style: context.textTheme.displayMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Divider(
                            thickness: 1.5,
                            height: 1,
                            color: context.colors.divider,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Recipe list ─────────────────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final recipe = filtered[i];
                          return RecipeCard(
                            recipe: recipe,
                            heroTagPrefix: 'categories',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipeId: recipe.id),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: TextField(
        controller: _searchController,
        style: context.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm công thức...',
          hintStyle: context.textTheme.bodyLarge!.copyWith(
            color: context.colors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.colors.textHint,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.colors.textHint, size: 20),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: context.colors.surfaceElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.colors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: context.colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 72,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final name = cat['name'] as String;
        final icon = cat['icon'] as IconData;
        final isSelected = _selectedCategory == name;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedCategory = isSelected ? null : name;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.grey.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.textSecondary,
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: context.textTheme.labelSmall!.copyWith(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                    ? Icons.restaurant_menu_rounded
                    : Icons.search_off_rounded,
                size: 40,
                color: context.colors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != null
                  ? 'Không có công thức "$_selectedCategory"'
                  : _searchQuery.isNotEmpty
                      ? 'Không tìm thấy "$_searchQuery"'
                      : 'Chưa có công thức nào',
              style: context.textTheme.headlineSmall!.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
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
      ),
    );
  }
}
