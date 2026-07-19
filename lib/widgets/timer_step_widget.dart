import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/step_model.dart';
import '../services/timer_service.dart';
import '../services/notification_service.dart';
import 'app_image.dart';
import 'app_theme.dart';
import 'step_block_widget.dart';

class TimerStepWidget extends StatefulWidget {
  final StepModel step;
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;

  const TimerStepWidget({
    super.key,
    required this.step,
    required this.currentIndex,
    required this.totalSteps,
    required this.onNext,
    this.onPrevious,
  });

  @override
  State<TimerStepWidget> createState() => _TimerStepWidgetState();
}

class _TimerStepWidgetState extends State<TimerStepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _notificationSent = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Init timer for this step without starting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = context.read<TimerService>();
      timerService.init(
        widget.step.durationSeconds ?? 60,
        onCompleted: _onTimerCompleted,
      );
      _notificationSent = false;
    });
  }

  @override
  void didUpdateWidget(TimerStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      final timerService = context.read<TimerService>();
      timerService.init(
        widget.step.durationSeconds ?? 60,
        onCompleted: _onTimerCompleted,
      );
      _notificationSent = false;
    }
  }

  void _onTimerCompleted() {
    if (!_notificationSent) {
      _notificationSent = true;
      NotificationService().showTimerCompleteNotification(
        stepName: widget.step.name,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timer, _) {
        final color = _getTimerColor(timer.status);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step image
            if (widget.step.imagePath != null &&
                widget.step.imagePath!.isNotEmpty)
              _buildStepImage(),

            const SizedBox(height: 20),



            // Instruction
            if (widget.step.instruction.isNotEmpty)
              Text(
                widget.step.instruction,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
            const SizedBox(height: 16),

            // Blocks
            if (widget.step.blocks.isNotEmpty)
              ...widget.step.blocks.map((b) => StepBlockWidget(block: b)),

            const SizedBox(height: 32),

            // Timer circle
            Center(child: _buildTimerCircle(timer, color)),

            const SizedBox(height: 32),

            // Timer controls
            _buildTimerControls(timer),

            const Spacer(),

            // Next button (enabled after completion or anytime)
            _buildNavButtons(timer),
          ],
        );
      },
    );
  }

  Widget _buildStepImage() {
    return AppImage(
      imagePath: widget.step.imagePath,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(16),
      placeholder: const SizedBox.shrink(),
    );
  }


  Widget _buildTimerCircle(TimerService timer, Color color) {
    return ScaleTransition(
      scale: timer.isRunning ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background track
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 10,
                valueColor:
                    AlwaysStoppedAnimation(AppColors.surfaceElevated),
              ),
            ),
            // Progress
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: timer.isIdle ? 0 : timer.progress,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            // Time text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timer.formattedTime, style: AppTextStyles.timerDisplay.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(
                  _getStatusLabel(timer.status),
                  style: AppTextStyles.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerControls(TimerService timer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        _controlButton(
          icon: Icons.replay_rounded,
          label: 'Làm lại',
          onTap: () => timer.start(
            widget.step.durationSeconds ?? 60,
            onCompleted: _onTimerCompleted,
          ),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 20),

        // Play / Pause
        GestureDetector(
          onTap: () {
            if (timer.isRunning) {
              timer.pause();
            } else if (timer.isPaused) {
              timer.resume();
            } else {
              timer.start(
                widget.step.durationSeconds ?? 60,
                onCompleted: _onTimerCompleted,
              );
              _notificationSent = false;
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              timer.isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Skip
        _controlButton(
          icon: Icons.skip_next_rounded,
          label: 'Bỏ qua',
          onTap: () {
            timer.stop();
            widget.onNext();
          },
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildNavButtons(TimerService timer) {
    return Row(
      children: [
        if (widget.onPrevious != null) ...[
          OutlinedButton.icon(
            onPressed: widget.onPrevious,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: timer.isCompleted
                ? () {
                    timer.stop();
                    widget.onNext();
                  }
                : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              widget.currentIndex == widget.totalSteps - 1
                  ? 'Hoàn thành'
                  : 'Tiếp tục',
              style: AppTextStyles.labelLarge.copyWith(
                color: timer.isCompleted ? Colors.white : AppColors.textHint,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  timer.isCompleted ? AppColors.success : AppColors.surfaceElevated,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTimerColor(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return AppColors.timerActive;
      case TimerStatus.paused:
        return AppColors.timerPaused;
      case TimerStatus.completed:
        return AppColors.timerCompleted;
      default:
        return AppColors.textHint;
    }
  }

  String _getStatusLabel(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return 'Đang chạy';
      case TimerStatus.paused:
        return 'Tạm dừng';
      case TimerStatus.completed:
        return 'Hoàn thành!';
      default:
        return 'Sẵn sàng';
    }
  }
}
