import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, themeProvider),
            SliverToBoxAdapter(
              child: Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  if (provider.recipes.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return const SizedBox.shrink(); // Handled by Grid below
                },
              ),
            ),
            Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                if (provider.recipes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return _buildRecipeGrid(context, provider.recipes, provider);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _openRecipeForm(context),
              elevation: 0,
              backgroundColor: Colors.transparent,
              hoverElevation: 0,
              focusElevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Thêm công thức',
                style: context.textTheme.labelLarge!.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    
    // Determine greeting based on time
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng,';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều,';
    } else {
      greeting = 'Chào buổi tối,';
    }

    return SliverAppBar(
      expandedHeight: 140,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.background.withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                'CookFlow',
                style: context.textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [context.colors.primary, context.colors.primaryLight],
                    ).createShader(const Rect.fromLTWH(0, 0, 160, 40)),
                ),
              ),
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: context.textTheme.bodyLarge!.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<RecipeProvider>(
                      builder: (context, provider, _) => Text(
                        'Sẵn sàng nấu món mới chưa?',
                        style: context.textTheme.headlineMedium!.copyWith(
                          color: context.colors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : context.colors.textPrimary,
            ),
            tooltip: 'Đổi giao diện',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.5),
            radius: 1.5,
            colors: [
              context.colors.primary.withValues(alpha: 0.15),
              context.colors.background,
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 36,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Chưa có công thức nào',
              style: context.textTheme.headlineLarge!.copyWith(
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thêm công thức đầu tiên của bạn để bắt đầu.',
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(
    BuildContext context,
    List<Recipe> recipes,
    RecipeProvider provider,
  ) {
    // Group recipes into chunks: [1, 2, 1, 2...]
    final List<List<Recipe>> chunks = [];
    int i = 0;
    while (i < recipes.length) {
      if (chunks.length % 2 == 0) {
        // Chunk of 1 large item
        chunks.add([recipes[i]]);
        i++;
      } else {
        // Chunk of 2 small items
        if (i + 1 < recipes.length) {
          chunks.add([recipes[i], recipes[i + 1]]);
          i += 2;
        } else {
          chunks.add([recipes[i]]);
          i++;
        }
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, chunkIndex) {
            final chunk = chunks[chunkIndex];
            
            if (chunk.length == 1) {
              final recipe = chunk[0];
              final stepCount = (recipe.pages != null && recipe.pages!.isNotEmpty)
                  ? recipe.pages!.fold<int>(0, (sum, page) => sum + page.stepIds.length)
                  : recipe.stepIds.length;
                  
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: RecipeCard(
                  recipe: recipe,
                  stepCount: stepCount,
                  isLarge: true,
                  onTap: () => _openRecipeDetail(context, recipe),
                  onLongPress: () => _showRecipeOptions(context, recipe, provider),
                ),
              );
            } else {
              // 2 items row
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSmallCard(context, chunk[0], provider),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSmallCard(context, chunk[1], provider),
                    ),
                  ],
                ),
              );
            }
          },
          childCount: chunks.length,
        ),
      ),
    );
  }

  Widget _buildSmallCard(BuildContext context, Recipe recipe, RecipeProvider provider) {
    final stepCount = (recipe.pages != null && recipe.pages!.isNotEmpty)
        ? recipe.pages!.fold<int>(0, (sum, page) => sum + page.stepIds.length)
        : recipe.stepIds.length;
        
    return RecipeCard(
      recipe: recipe,
      stepCount: stepCount,
      isLarge: false,
      onTap: () => _openRecipeDetail(context, recipe),
      onLongPress: () => _showRecipeOptions(context, recipe, provider),
    );
  }

  void _openRecipeForm(BuildContext context, {Recipe? recipe}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeFormScreen(recipe: recipe),
      ),
    );
  }

  void _openRecipeDetail(BuildContext context, Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }

  void _showRecipeOptions(
    BuildContext context,
    Recipe recipe,
    RecipeProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                recipe.name,
                style: context.textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: context.colors.primary),
              title: const Text('Chỉnh sửa công thức'),
              onTap: () {
                Navigator.pop(ctx);
                _openRecipeForm(context, recipe: recipe);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: context.colors.error),
              title: Text(
                'Xóa công thức',
                style: TextStyle(color: context.colors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, recipe, provider);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Recipe recipe,
    RecipeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surfaceElevated,
        title: Text('Xóa công thức?', style: context.textTheme.headlineMedium),
        content: Text(
          '"${recipe.name}" và toàn bộ các bước thực hiện sẽ bị xóa.',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteRecipe(recipe.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa "${recipe.name}"')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
