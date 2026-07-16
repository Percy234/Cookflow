import 'package:flutter/material.dart';
import '../models/step_model.dart';
import 'app_image.dart';
import 'app_theme.dart';

class StepCard extends StatelessWidget {
  final StepModel step;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDraggable;

  const StepCard({
    super.key,
    required this.step,
    required this.index,
    this.onEdit,
    this.onDelete,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.isTimerStep
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Step number + type indicator
          _buildLeading(),
          // Content
          Expanded(child: _buildContent()),
          // Actions
          if (onEdit != null || onDelete != null) _buildActions(),
          if (isDraggable) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.drag_handle_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildLeading() {
    final isTimer = step.isTimerStep;
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isTimer
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}',
            style: AppTextStyles.headlineMedium.copyWith(
              color: isTimer ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            isTimer ? Icons.timer_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: isTimer ? AppColors.primary : AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.name,
                  style: AppTextStyles.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildTypeChip(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            step.instruction,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (step.isTimerStep && step.durationSeconds != null) ...[
            const SizedBox(height: 6),
            _buildTimerInfo(),
          ],
          if (step.imagePath != null && step.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppImage(
              imagePath: step.imagePath,
              height: 60,
              width: 80,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
              placeholder: const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    final isTimer = step.isTimerStep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTimer
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isTimer ? 'Timer' : 'Static',
        style: AppTextStyles.bodySmall.copyWith(
          color: isTimer ? AppColors.primary : AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimerInfo() {
    final minutes = (step.durationSeconds! ~/ 60);
    final seconds = step.durationSeconds! % 60;
    final timeStr = minutes > 0
        ? seconds > 0
            ? '${minutes}p ${seconds}s'
            : '$minutes phút'
        : '$seconds giây';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          timeStr,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Chỉnh sửa',
            visualDensity: VisualDensity.compact,
          ),
        if (onDelete != null)
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            tooltip: 'Xóa',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Xóa bước?', style: AppTextStyles.headlineMedium),
        content: Text(
          'Bước "${step.name}" sẽ bị xóa vĩnh viễn.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
