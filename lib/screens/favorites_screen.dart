import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_image.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer2<FavoritesProvider, RecipeProvider>(
                builder: (context, favProvider, recipeProvider, _) {
                  final favoriteRecipes = recipeProvider.recipes
                      .where((r) => favProvider.isFavorite(r.id))
                      .toList();

                  if (favoriteRecipes.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: favoriteRecipes.length,
                    itemBuilder: (context, i) {
                      final recipe = favoriteRecipes[i];
                      return _buildGridCard(context, recipe);
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
            'Yêu thích',
            style: context.textTheme.displayMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Những công thức bạn yêu thích nhất',
            style: context.textTheme.bodyMedium!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
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
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 44,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có công thức yêu thích',
            style: context.textTheme.headlineSmall!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hoàn thành công thức rồi nhấn ♥ để lưu vào đây.',
            style: context.textTheme.bodySmall!.copyWith(
              color: context.colors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
        ),
      ),
      child: Container(
        color: Colors.transparent, // Nền trong suốt chứa toàn bộ card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nền màu 1f1f1f
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1F1F1F)
                    : const Color(0xFFF7F2E9),
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias, // Cắt viền ảnh theo bo góc của container
              padding: const EdgeInsets.only(bottom: 10), // Tăng khoảng trống bên dưới ảnh
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      // Ảnh đè sát viền trên, trái, phải
                      AspectRatio(
                        aspectRatio: 1,
                        child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
                            ? AppImage(
                                imagePath: recipe.imagePath,
                                fit: BoxFit.cover,
                                placeholder: Container(color: context.colors.surfaceElevated),
                              )
                            : Container(
                                color: context.colors.surfaceElevated,
                                child: Icon(Icons.restaurant, color: context.colors.textHint),
                              ),
                      ),
                      // Góc trên trái: Độ khó (badge trắng)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _buildDifficultyBadge(context, recipe.difficulty),
                      ),
                      // Góc trên phải: Nút xoá yêu thích
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Consumer<FavoritesProvider>(
                          builder: (_, favProvider, __) {
                            return GestureDetector(
                              onTap: () => favProvider.toggleFavorite(recipe.id),
                              child: Container(
                                height: 24,
                                width: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Thông tin phân loại (chữ to hơn)
                  Text(
                    recipe.category?.isNotEmpty == true ? recipe.category! : 'Món ăn',
                    style: context.textTheme.labelSmall!.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tên món nhô ra bên dưới
            Expanded(
              child: Text(
                recipe.name,
                style: context.textTheme.labelMedium!.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context, int difficulty) {
    String label;
    Color color;
    switch (difficulty) {
      case 1:
        label = 'Trung bình';
        color = Colors.orange.shade800;
        break;
      case 2:
        label = 'Khó';
        color = Colors.red.shade700;
        break;
      case 0:
      default:
        label = 'Dễ';
        color = Colors.green.shade700;
        break;
    }
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}
