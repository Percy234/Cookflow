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

/// View mode for the recipe list.
enum _ViewMode { list, grid }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  _ViewMode _viewMode = _ViewMode.list;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Sticky top bar ──────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: _buildTopBar(context, themeProvider),
              ),
            ),
            // ── Hero header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeroHeader(context),
            ),
            // ── Section header with view toggle ─────────────────────
            Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                if (provider.recipes.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _buildSectionHeader(context),
                );
              },
            ),
            // ── Empty state ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  if (provider.recipes.isEmpty) return _buildEmptyState(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            // ── Recipe list / grid ──────────────────────────────────────
            Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                if (provider.recipes.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return _viewMode == _ViewMode.list
                    ? _buildListView(context, provider.recipes, provider)
                    : _buildGridView(context, provider.recipes, provider);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecipeForm(context),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Thêm công thức',
          style: context.textTheme.labelLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: context.colors.background.withOpacity(0.88),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand name (Logo removed as requested)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Cook',
                          style: context.textTheme.headlineLarge!.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        TextSpan(
                          text: 'flow',
                          style: context.textTheme.headlineLarge!.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Theme toggle
              GestureDetector(
                onTap: () => themeProvider.toggleTheme(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFFFFC107)
                        : context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header: label + toggle button ────────────────────────────
  Widget _buildSectionHeader(BuildContext context) {
    final isGrid = _viewMode == _ViewMode.grid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Công thức của bạn',
            style: context.textTheme.headlineSmall!.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          // Toggle pill button
          GestureDetector(
            onTap: () => setState(() {
              _viewMode = isGrid ? _ViewMode.list : _ViewMode.grid;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: isGrid ? 0.12 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: isGrid ? 0.4 : 0.25),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                  key: ValueKey(isGrid),
                  size: 20,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng 👋';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều 👋';
    } else {
      greeting = 'Chào buổi tối 👋';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: context.textTheme.bodyLarge!.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Consumer<RecipeProvider>(
            builder: (context, provider, _) {
              final count = provider.recipes.length;
              final headline = count == 0
                  ? 'Bắt đầu tạo công thức\nđầu tiên của bạn.'
                  : 'Bạn có $count công thức.';
              return Text(
                headline,
                style: context.textTheme.displayMedium!.copyWith(
                  height: 1.15,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: context.colors.divider, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_outlined,
                size: 32,
                color: context.colors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có công thức nào',
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút bên dưới để tạo\ncông thức đầu tiên của bạn.',
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── LIST MODE: alternating bento (1 large → 2 small) ────────────────
  Widget _buildListView(
    BuildContext context,
    List<Recipe> recipes,
    RecipeProvider provider,
  ) {
    final List<List<Recipe>> chunks = [];
    int i = 0;
    while (i < recipes.length) {
      if (chunks.length % 2 == 0) {
        chunks.add([recipes[i]]);
        i++;
      } else {
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, chunkIndex) {
            final chunk = chunks[chunkIndex];
            if (chunk.length == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RecipeCard(
                  recipe: chunk[0],
                  stepCount: _stepCount(chunk[0]),
                  isLarge: true,
                  onTap: () => _openRecipeDetail(context, chunk[0]),
                  onLongPress: () =>
                      _showRecipeOptions(context, chunk[0], provider),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _buildSmallCard(context, chunk[0], provider)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildSmallCard(context, chunk[1], provider)),
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

  // ── GRID MODE: uniform 2-column grid ────────────────────────────────
  Widget _buildGridView(
    BuildContext context,
    List<Recipe> recipes,
    RecipeProvider provider,
  ) {
    final List<List<Recipe>> rows = [];
    for (int i = 0; i < recipes.length; i += 2) {
      if (i + 1 < recipes.length) {
        rows.add([recipes[i], recipes[i + 1]]);
      } else {
        rows.add([recipes[i]]);
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, rowIndex) {
            final row = rows[rowIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSmallCard(context, row[0], provider)),
                  const SizedBox(width: 14),
                  if (row.length > 1)
                    Expanded(
                        child: _buildSmallCard(context, row[1], provider))
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            );
          },
          childCount: rows.length,
        ),
      ),
    );
  }

  Widget _buildSmallCard(
      BuildContext context, Recipe recipe, RecipeProvider provider) {
    return RecipeCard(
      recipe: recipe,
      stepCount: _stepCount(recipe),
      isLarge: false,
      onTap: () => _openRecipeDetail(context, recipe),
      onLongPress: () => _showRecipeOptions(context, recipe, provider),
    );
  }

  int _stepCount(Recipe recipe) =>
      (recipe.pages != null && recipe.pages!.isNotEmpty)
          ? recipe.pages!
              .fold<int>(0, (sum, page) => sum + page.stepIds.length)
          : recipe.stepIds.length;

  void _openRecipeForm(BuildContext context, {Recipe? recipe}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: recipe)),
    );
  }

  void _openRecipeDetail(BuildContext context, Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipeId: recipe.id)),
    );
  }

  void _showRecipeOptions(
    BuildContext context,
    Recipe recipe,
    RecipeProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                recipe.name,
                style: context.textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: context.colors.divider, height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.edit_rounded, color: context.colors.primary),
              title: const Text('Chỉnh sửa công thức'),
              onTap: () {
                Navigator.pop(ctx);
                _openRecipeForm(context, recipe: recipe);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading:
                  Icon(Icons.delete_outline_rounded, color: context.colors.error),
              title: Text('Xóa công thức',
                  style: TextStyle(color: context.colors.error)),
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
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

// ── Sticky header delegate ───────────────────────────────────────────────
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
