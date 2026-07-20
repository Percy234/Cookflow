import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/step_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/app_theme.dart';
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
                      _buildRecipeName(context, recipe),
                      const SizedBox(height: 12),
                      if (recipe.description.isNotEmpty)
                        _buildDescription(context, recipe),
                      const SizedBox(height: 20),
                      _buildStatsRow(context, recipe, steps),
                      if (recipe.additionalInfo != null &&
                          recipe.additionalInfo!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildAdditionalInfo(context, recipe),
                      ],
                      const SizedBox(height: 28),
                      _buildWorkflowSection(context, recipe, steps, provider),
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
      expandedHeight: recipe.imagePath != null ? 260 : 0,
      pinned: true,
      backgroundColor: context.colors.background,
      actions: const [],
      flexibleSpace: recipe.imagePath != null
          ? FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe-${recipe.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      imagePath: recipe.imagePath,
                      fit: BoxFit.cover,
                      placeholder: _imagePlaceholder(context),
                    ),
                    // Gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            context.colors.background,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withValues(alpha: 0.3),
            context.colors.primaryDark.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_rounded, size: 80, color: context.colors.primary),
      ),
    );
  }

  Widget _buildRecipeName(BuildContext context, Recipe recipe) {
    return Text(recipe.name, style: context.textTheme.displayLarge);
  }

  Widget _buildDescription(BuildContext context, Recipe recipe) {
    return Text(
      recipe.description,
      style: context.textTheme.bodyLarge!.copyWith(color: context.colors.textSecondary),
    );
  }

  Widget _buildStatsRow(BuildContext context, Recipe recipe, List<StepModel> steps) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _statChip(
          context: context,
          icon: Icons.format_list_numbered_rounded,
          value: '${steps.length}',
          label: 'bước',
          color: context.colors.primary,
        ),
        if (steps.any((s) => s.isTimerStep))
          _statChip(
            context: context,
            icon: Icons.timer_rounded,
            value: '${steps.where((s) => s.isTimerStep).length}',
            label: 'hẹn giờ',
            color: context.colors.warning,
          ),
        if (recipe.pages != null && recipe.pages!.length > 1)
          _statChip(
            context: context,
            icon: Icons.account_tree_rounded,
            value: '${recipe.pages!.length}',
            label: 'giai đoạn',
            color: context.colors.info,
          ),
      ],
    );
  }

  Widget _statChip({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: context.textTheme.labelLarge!.copyWith(color: color),
                ),
                TextSpan(
                  text: ' $label',
                  style: context.textTheme.bodySmall!.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildWorkflowSection(
    BuildContext context,
    Recipe recipe,
    List<StepModel> steps,
    RecipeProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Quy trình thực hiện', style: context.textTheme.headlineLarge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recipe.pages != null && recipe.pages!.length > 1) ...[
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeFlowScreen(
                          recipe: recipe,
                          pages: recipe.pages!,
                        ),
                      ),
                    ),
                    icon: Icon(
                      Icons.account_tree_rounded,
                      size: 20,
                      color: context.colors.primary,
                    ),
                    tooltip: 'Nối quy trình (Flow)',
                    style: IconButton.styleFrom(
                      backgroundColor: context.colors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeEditorScreen(recipe: recipe),
                    ),
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: context.colors.primary,
                  ),
                  tooltip: 'Quản lý quy trình',
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeFormScreen(recipe: recipe),
                    ),
                  ),
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: context.colors.primary,
                  ),
                  tooltip: 'Chỉnh sửa thông tin',
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (steps.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: context.colors.textHint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chưa có bước nào. Nhấn "Quản lý" để thêm bước.',
                    style: context.textTheme.bodyMedium!.copyWith(
                      color: context.colors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...steps.asMap().entries.map(
                (entry) => _buildStepPreviewTile(context, entry.key, entry.value),
              ),
      ],
    );
  }

  Widget _buildStepPreviewTile(BuildContext context, int index, StepModel step) {
    final isTimer = step.isTimerStep;
    String displayName = step.name;
    if (RegExp(r'^(Trang|Bước)\s+\d+$').hasMatch(displayName)) {
      displayName = 'Bước ${index + 1}';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTimer ? context.colors.primary.withValues(alpha: 0.25) : context.colors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTimer
                  ? context.colors.primary.withValues(alpha: 0.15)
                  : context.colors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: context.textTheme.labelLarge!.copyWith(
                  color: isTimer ? context.colors.primary : context.colors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(displayName, style: context.textTheme.bodyMedium),
          ),
          Icon(
            isTimer ? Icons.timer_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: isTimer ? context.colors.primary : context.colors.textHint,
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
        child: ElevatedButton.icon(
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
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            steps.isEmpty ? 'Thêm bước để bắt đầu' : 'Bắt đầu nấu',
            style: context.textTheme.labelLarge!.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor:
                steps.isEmpty ? context.colors.surfaceElevated : context.colors.primary,
          ),
        ),
      ),
    );
  }
}
