import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_image.dart';
import 'recipe_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day/$month/$year';
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
            Expanded(
              child: Consumer2<HistoryProvider, RecipeProvider>(
                builder: (context, historyProvider, recipeProvider, _) {
                  final entries = historyProvider.entries;

                  if (entries.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final recipe = recipeProvider.getRecipeById(entry.recipeId);

                      if (recipe == null) {
                        // Recipe was deleted – show placeholder
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildDeletedCard(context, entry),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildHistoryCard(context, recipe, entry, historyProvider, i),
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
            'Lịch sử',
            style: context.textTheme.displayMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Những công thức bạn đã thực hiện',
            style: context.textTheme.bodyMedium!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    dynamic recipe,
    HistoryEntry entry,
    HistoryProvider historyProvider,
    int index,
  ) {
    return Dismissible(
      key: Key('${entry.recipeId}_${entry.executedAt.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => historyProvider.removeEntryAt(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        ),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ảnh được cách viền card bởi padding (bo góc 4px ở 3 góc, 12px ở dưới phải)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: AppImage(
                        imagePath: recipe.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Tên món và thời gian (căn giữa dọc)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: context.textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: context.colors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(entry.executedAt),
                              style: context.textTheme.bodySmall!.copyWith(
                                color: context.colors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icon loại món (màu đậm hơn, nhận diện rõ nét)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _getCategoryIcon(recipe.category),
                      size: 58,
                      color: context.colors.textSecondary.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
            // Nút xoá nhanh trên từng card
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => historyProvider.removeEntryAt(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceElevated.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: context.colors.textHint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) return Icons.restaurant;
    final lower = category.toLowerCase();
    if (lower.contains('nấu') || lower.contains('canh')) return Icons.soup_kitchen_rounded;
    if (lower.contains('nướng')) return Icons.outdoor_grill_rounded;
    if (lower.contains('hấp')) return Icons.set_meal_rounded;
    if (lower.contains('chiên') || lower.contains('xào')) return Icons.rice_bowl_rounded;
    if (lower.contains('bánh')) return Icons.cake_rounded;
    if (lower.contains('nước') || lower.contains('uống')) return Icons.local_cafe_rounded;
    if (lower.contains('salad') || lower.contains('trộn')) return Icons.eco_rounded;
    return Icons.restaurant;
  }

  Widget _buildDeletedCard(BuildContext context, HistoryEntry entry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công thức đã bị xóa',
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: context.colors.textHint,
                  ),
                ),
                Text(
                  _formatTimestamp(entry.executedAt),
                  style: context.textTheme.bodySmall!.copyWith(
                    color: context.colors.textHint,
                  ),
                ),
              ],
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
              color: context.colors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 44,
              color: context.colors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử',
            style: context.textTheme.headlineSmall!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các công thức bạn thực hiện sẽ hiển thị ở đây.',
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
