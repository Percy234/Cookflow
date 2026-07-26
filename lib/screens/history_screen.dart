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
                        child: _buildHistoryCard(context, recipe, entry, recipeProvider),
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
      child: Row(
        children: [
          Expanded(
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
          ),
          Consumer<HistoryProvider>(
            builder: (context, histProvider, _) {
              if (histProvider.entries.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmClear(context, histProvider),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Xóa'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textHint,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, HistoryProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử thực hiện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.clearHistory();
    }
  }

  Widget _buildHistoryCard(BuildContext context, dynamic recipe, HistoryEntry entry, RecipeProvider recipeProvider) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: AppImage(
                  imagePath: recipe.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: context.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (recipe.category != null)
                      Text(
                        recipe.category!,
                        style: context.textTheme.bodySmall!.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
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
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.colors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
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
