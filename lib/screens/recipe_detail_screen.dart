import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/step_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/app_theme.dart';
import '../widgets/formatted_text.dart';
import 'execution_screen.dart';
import 'recipe_editor_screen.dart';
import 'recipe_flow_screen.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        final recipe = provider.getRecipeById(recipeId);
        if (recipe == null) {
          return Scaffold(
            backgroundColor: context.colors.background,
            appBar: AppBar(title: const Text('Không tìm thấy')),
            body: const Center(child: Text('Công thức không tồn tại.')),
          );
        }

        final steps = provider.getStepsForRecipe(recipe);

        return Scaffold(
          backgroundColor: context.colors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, recipe, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Icon style image
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.colors.divider),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AppImage(
                              imagePath: recipe.imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Name and Category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.name,
                                  style: context.textTheme.displayLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (recipe.category != null && recipe.category!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    recipe.category!,
                                    style: context.textTheme.titleMedium!.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      _buildPlayStoreStats(context, recipe, steps),
                      const SizedBox(height: 32),

                      if (recipe.descriptionImages.isNotEmpty) ...[
                        _buildDescriptionImages(context, recipe),
                        const SizedBox(height: 24),
                      ],

                      if (recipe.description.isNotEmpty) ...[
                        Text('Về món ăn này', style: context.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        _buildDescription(context, recipe),
                      ],

                      if (recipe.additionalInfo != null &&
                          recipe.additionalInfo!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildAdditionalInfo(context, recipe),
                      ],
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, recipe, steps),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    Recipe recipe,
    RecipeProvider provider,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.colors.background,
      actions: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Tùy chọn chỉnh sửa',
          onSelected: (value) {
            if (value == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: recipe)),
              );
            } else if (value == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipe: recipe)),
              );
            } else if (value == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeFlowScreen(
                    recipe: recipe,
                    pages: recipe.pages!,
                  ),
                ),
              );
            } else if (value == 3) {
              _confirmDeleteRecipe(context, recipe, provider);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 20, color: context.colors.primary),
                  const SizedBox(width: 12),
                  const Text('Chỉnh sửa thông tin'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: context.colors.primary),
                  const SizedBox(width: 12),
                  const Text('Quản lý quy trình'),
                ],
              ),
            ),
            if (recipe.pages != null && recipe.pages!.length > 1)
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.account_tree_rounded, size: 20, color: context.colors.primary),
                    const SizedBox(width: 12),
                    const Text('Nối quy trình (Flow)'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: [
                  Icon(Icons.delete_forever_rounded, size: 20, color: context.colors.primary),
                  const SizedBox(width: 12),
                  const Text('Xóa công thức'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildDescription(BuildContext context, Recipe recipe) {
    return FormattedText(
      text: recipe.description,
      style: context.textTheme.bodyLarge!.copyWith(color: context.colors.textSecondary),
    );
  }

  Widget _buildDescriptionImages(BuildContext context, Recipe recipe) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth * 0.8;
    final itemHeight = itemWidth * (9 / 16);

    if (recipe.descriptionImages.length == 1) {
      final singleWidth = screenWidth - 48; // Screen width minus horizontal padding (24 * 2)
      final singleHeight = singleWidth * (9 / 16);
      return Container(
        width: double.infinity,
        height: singleHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AppImage(
          imagePath: recipe.descriptionImages[0],
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: recipe.descriptionImages.length,
        itemBuilder: (context, index) {
          return Container(
            width: itemWidth,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AppImage(
              imagePath: recipe.descriptionImages[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayStoreStats(BuildContext context, Recipe recipe, List<StepModel> steps) {
    String diffText = 'Dễ';
    if (recipe.difficulty == 1) diffText = 'Trung bình';
    else if (recipe.difficulty == 2) diffText = 'Khó';

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _buildPlayStoreStatItem(context, diffText, 'Độ khó')),
          VerticalDivider(color: context.colors.divider, thickness: 1, width: 1),
          Expanded(child: _buildPlayStoreStatItem(context, recipe.estimatedTime ?? '--', 'Thời gian')),
          VerticalDivider(color: context.colors.divider, thickness: 1, width: 1),
          Expanded(child: _buildPlayStoreStatItem(context, '${steps.length}', 'Số bước')),
        ],
      ),
    );
  }

  Widget _buildPlayStoreStatItem(BuildContext context, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall!.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(BuildContext context, Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nguyên liệu', style: context.textTheme.headlineLarge),
        const SizedBox(height: 12),
        ...recipe.ingredients.map(
          (ing) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(ing.name, style: context.textTheme.bodyMedium),
                ),
                Text(
                  '${ing.amount} ${ing.unit}'.trim(),
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, Recipe recipe) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: context.colors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recipe.additionalInfo!,
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Recipe recipe,
    List<StepModel> steps,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(
          top: BorderSide(color: context.colors.divider),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: steps.isEmpty
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExecutionScreen(
                        recipeId: recipe.id,
                        steps: steps,
                      ),
                    ),
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            'Bắt đầu nấu',
            style: context.textTheme.titleMedium!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRecipe(
    BuildContext context,
    Recipe recipe,
    RecipeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Xóa công thức?', style: context.textTheme.headlineMedium),
        content: Text(
          'Bạn có chắc chắn muốn xóa công thức "${recipe.name}"? Hành động này không thể hoàn tác.',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await provider.deleteRecipe(recipe.id);
              if (context.mounted) {
                Navigator.pop(context); // Close detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa công thức thành công'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
