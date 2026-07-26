import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/step_model.dart';
import '../providers/execution_provider.dart';
import '../services/timer_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/static_step_widget.dart';
import '../widgets/timer_step_widget.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_image.dart';

class ExecutionScreen extends StatefulWidget {
  final String recipeId;
  final List<StepModel> steps;

  const ExecutionScreen({
    super.key,
    required this.recipeId,
    required this.steps,
  });

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> {
  late TimerService _timerService;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _timerService = context.read<TimerService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExecutionProvider>().startExecution(widget.steps);
    });
  }

  @override
  void dispose() {
    Future.microtask(() => _timerService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExecutionProvider>(
      builder: (context, exec, _) {
        if (exec.isCompleted) {
          _endTime ??= DateTime.now();
          return _buildCompletionScreen(context);
        }

        final step = exec.currentStep;
        if (step == null) {
          return Scaffold(
            backgroundColor: context.colors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: _buildAppBar(context, exec),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: step.isTimerStep
                ? TimerStepWidget(
                    key: ValueKey(step.id),
                    step: step,
                    currentIndex: exec.currentIndex,
                    totalSteps: exec.totalSteps,
                    onNext: exec.nextStep,
                    onPrevious: exec.hasPrevious ? exec.previousStep : null,
                  )
                : StaticStepWidget(
                    key: ValueKey(step.id),
                    step: step,
                    currentIndex: exec.currentIndex,
                    totalSteps: exec.totalSteps,
                    onNext: exec.nextStep,
                    onPrevious: exec.hasPrevious ? exec.previousStep : null,
                  ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ExecutionProvider exec) {
    final progress = exec.totalSteps > 0
        ? (exec.currentIndex + 1) / exec.totalSteps
        : 0.0;

    final step = exec.currentStep;
    final isTimer = step?.isTimerStep ?? false;
    final badgeColor = isTimer ? context.colors.primary : context.colors.success;
    final badgeIcon = isTimer ? Icons.timer_rounded : Icons.check_circle_outline_rounded;

    String stepName = step?.name ?? 'Bước ${exec.currentIndex + 1}';
    if (RegExp(r'^(Trang|Bước)\s+\d+$').hasMatch(stepName)) {
      stepName = 'Bước ${exec.currentIndex + 1}';
    }

    return AppBar(
      backgroundColor: context.colors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 14, color: badgeColor),
                const SizedBox(width: 6),
                Text(
                  '$stepName / ${exec.totalSteps}',
                  style: context.textTheme.labelLarge!.copyWith(color: badgeColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(context.colors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
      toolbarHeight: 70,
      leading: IconButton(
        onPressed: () => _confirmExit(context),
        icon: Icon(Icons.close_rounded, color: context.colors.textPrimary),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    List<String> parts = [];
    if (hours > 0) parts.add('$hours giờ');
    if (minutes > 0) parts.add('$minutes phút');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds giây');
    return parts.join(' ');
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildCompletionScreen(BuildContext context) {
    Recipe? recipe;
    try {
      final recipeProvider = context.read<RecipeProvider>();
      recipe = recipeProvider.recipes.firstWhere((r) => r.id == widget.recipeId);
    } catch (_) {}

    final difficultyText = recipe != null
        ? (recipe.difficulty == 0
            ? 'Dễ'
            : (recipe.difficulty == 1 ? 'Trung bình' : 'Khó'))
        : '';
    final difficultyIcon = recipe != null
        ? (recipe.difficulty == 0
            ? Icons.sentiment_satisfied_rounded
            : (recipe.difficulty == 1
                ? Icons.sentiment_neutral_rounded
                : Icons.local_fire_department_rounded))
        : Icons.sentiment_satisfied_rounded;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 56,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chúc mừng!',
                        style: context.textTheme.headlineLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      if (recipe != null)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.colors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AppImage(
                                      imagePath: recipe.imagePath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Đã hoàn thành:',
                                      style: context.textTheme.bodyMedium!.copyWith(
                                        color: context.colors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      recipe.name,
                                      style: context.textTheme.titleLarge!.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: context.colors.textPrimary,
                                        fontSize: 32,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (recipe.category != null)
                                          _buildBadge(
                                            context: context,
                                            icon: Icons.restaurant_menu_rounded,
                                            text: recipe.category!,
                                          ),
                                        _buildBadge(
                                          context: context,
                                          icon: difficultyIcon,
                                          text: difficultyText,
                                        ),
                                        if (recipe.estimatedTime != null)
                                          _buildBadge(
                                            context: context,
                                            icon: Icons.timer_outlined,
                                            text: recipe.estimatedTime!,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (_endTime != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.colors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.speed_rounded,
                                    color: context.colors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TỔNG THỜI GIAN THỰC HIỆN',
                                    style: context.textTheme.labelLarge!.copyWith(
                                      color: context.colors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _formatDuration(_endTime!.difference(_startTime)),
                                style: context.textTheme.displayMedium!.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 32,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_outline_rounded, size: 14, color: context.colors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTime(_startTime),
                                      style: context.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text('•', style: TextStyle(color: context.colors.divider)),
                                    ),
                                    Icon(Icons.check_circle_outline_rounded, size: 14, color: context.colors.success),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTime(_endTime!),
                                      style: context.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _startTime = DateTime.now();
                          _endTime = null;
                        });
                        context.read<ExecutionProvider>().startExecution(widget.steps);
                        context.read<TimerService>().stop();
                      },
                      icon: Icon(Icons.replay_rounded, color: context.colors.primary, size: 18),
                      label: Text(
                        'Làm lại',
                        style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: context.colors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Hoàn tất',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: context.colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: context.textTheme.labelSmall!.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionStat({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.colors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleLarge!.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.bodySmall!.copyWith(
              color: context.colors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Thoát quy trình?', style: context.textTheme.headlineMedium),
        content: Text(
          'Tiến trình thực hiện hiện tại sẽ bị hủy.',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tiếp tục nấu'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TimerService>().stop();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}
