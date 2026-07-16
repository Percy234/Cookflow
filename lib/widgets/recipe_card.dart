import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'app_image.dart';
import 'app_theme.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int stepCount;
  final bool isLarge; // For Bento grid

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onLongPress,
    this.stepCount = 0,
    this.isLarge = false,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(widget.isLarge ? 28 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: widget.isLarge ? 24 : 12,
                offset: Offset(0, widget.isLarge ? 8 : 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              Padding(
                padding: EdgeInsets.all(widget.isLarge ? 20 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipe.name,
                      style: widget.isLarge ? context.textTheme.headlineMedium : context.textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.recipe.description.isNotEmpty && widget.isLarge) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.recipe.description,
                        style: context.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (widget.recipe.description.isNotEmpty && !widget.isLarge) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.recipe.description,
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: widget.isLarge ? 16 : 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(
                          icon: Icons.format_list_numbered_rounded,
                          label: '${widget.stepCount} bước',
                          color: context.colors.primary,
                        ),
                        if (widget.recipe.ingredients.isNotEmpty) 
                          _buildChip(
                            icon: Icons.restaurant_menu_rounded,
                            label: '${widget.recipe.ingredients.length} nguyên liệu',
                            color: context.colors.info,
                          ),
                        _buildDifficultyChip(widget.recipe.difficulty, context),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final placeholder = _placeholderImage(context);
    if (widget.recipe.imagePath != null && widget.recipe.imagePath!.isNotEmpty) {
      return Hero(
        tag: 'recipe-${widget.recipe.id}',
        child: SizedBox(
          height: widget.isLarge ? 220 : 160,
          width: double.infinity,
          child: AppImage(
            imagePath: widget.recipe.imagePath,
            height: widget.isLarge ? 220 : 160,
            fit: BoxFit.cover,
            placeholder: placeholder,
          ),
        ),
      );
    }
    return placeholder;
  }

  Widget _placeholderImage(BuildContext context) {
    return Container(
      height: widget.isLarge ? 220 : 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withValues(alpha: 0.3),
            context.colors.primaryDark.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 48,
          color: context.colors.primary,
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.textTheme.bodySmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(int difficulty, BuildContext context) {
    IconData icon;
    String label;
    Color color;

    switch (difficulty) {
      case 1:
        icon = Icons.sentiment_neutral_rounded;
        label = 'Trung bình';
        color = context.colors.warning;
        break;
      case 2:
        icon = Icons.local_fire_department_rounded;
        label = 'Khó';
        color = context.colors.error;
        break;
      case 0:
      default:
        icon = Icons.sentiment_satisfied_rounded;
        label = 'Dễ';
        color = context.colors.success;
        break;
    }

    return _buildChip(
      icon: icon,
      label: label,
      color: color,
    );
  }
}
