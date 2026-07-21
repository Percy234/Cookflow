import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/step_model.dart';
import '../providers/execution_provider.dart';
import '../services/timer_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/static_step_widget.dart';
import '../widgets/timer_step_widget.dart';

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

  Widget _buildCompletionScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon with glow effect
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.success.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.success.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: context.colors.success,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                '🎉 Hoàn thành!',
                style: context.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Bạn đã hoàn thành toàn bộ các bước.\nChúc bạn ngon miệng!',
                style: context.textTheme.bodyLarge!.copyWith(
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Stat cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _completionStat(
                    context: context,
                    icon: Icons.format_list_numbered_rounded,
                    value: '${widget.steps.length}',
                    label: 'bước\nhoàn thành',
                  ),
                  const SizedBox(width: 20),
                  _completionStat(
                    context: context,
                    icon: Icons.timer_rounded,
                    value: '${widget.steps.where((s) => s.isTimerStep).length}',
                    label: 'bước\nhẹn giờ',
                  ),
                ],
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Về trang chủ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: context.colors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.read<ExecutionProvider>().startExecution(widget.steps);
                  context.read<TimerService>().stop();
                },
                child: Text(
                  'Làm lại từ đầu',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.colors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.displayMedium!.copyWith(
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.bodySmall,
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
