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
    with TickerProviderStateMixin {
  // Shimmer sweep animation (runs while timer is active)
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  bool _notificationSent = false;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _shimmerAnim = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

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
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleButtonTap(TimerService timer) {
    if (timer.isCompleted) {
      timer.stop();
      widget.onNext();
      return;
    }
    if (timer.isRunning) {
      timer.pause();
    } else if (timer.isPaused) {
      timer.resume();
      _notificationSent = false;
    } else {
      timer.start(
        widget.step.durationSeconds ?? 60,
        onCompleted: _onTimerCompleted,
      );
      _notificationSent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timer, _) {
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
                style: context.textTheme.bodyMedium!.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),

            const SizedBox(height: 16),

            // Blocks
            if (widget.step.blocks.isNotEmpty)
              ...widget.step.blocks.map((b) => StepBlockWidget(block: b)),

            const Spacer(),

            // ─── Smart single timer button ───
            _buildSmartTimerButton(context, timer),

            // Back navigation (optional)
            if (widget.onPrevious != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Bước trước'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 4),
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

  Widget _buildSmartTimerButton(BuildContext context, TimerService timer) {
    final bool isCompleted = timer.isCompleted;
    final bool isIdle = timer.isIdle;
    final bool isPaused = timer.isPaused;
    final bool isRunning = timer.isRunning;

    final double fillProgress = isIdle ? 0.0 : timer.progress;

    // Foreground fill colour
    final Color fillColor = isCompleted
        ? context.colors.success
        : isPaused
            ? context.colors.timerPaused
            : context.colors.primary;

    // Button background colour
    final Color bgColor = isCompleted
        ? context.colors.success.withValues(alpha: 0.10)
        : context.colors.surfaceElevated;

    // Label text
    final String label;
    if (isCompleted) {
      label = widget.currentIndex == widget.totalSteps - 1
          ? 'Hoàn thành'
          : 'Tiếp tục';
    } else if (isIdle) {
      label = 'Bắt đầu';
    } else if (isPaused) {
      label = '${timer.formattedTime}  •  Chạm để tiếp tục';
    } else {
      label = timer.formattedTime;
    }

    // Icon
    final IconData icon = isCompleted
        ? Icons.arrow_forward_rounded
        : isIdle
            ? Icons.play_arrow_rounded
            : isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded;

    return GestureDetector(
      onTap: () => _handleButtonTap(timer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: fillColor.withValues(alpha: isIdle ? 0.35 : 0.5),
            width: 1.5,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: context.colors.success.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ── Fill wave (left → right) ──
            if (fillProgress > 0)
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 64),
                    painter: _WaveFillPainter(
                      progress: fillProgress,
                      fillColor: fillColor,
                      shimmerPos: isRunning ? _shimmerAnim.value : -2.0,
                    ),
                  );
                },
              ),

            // ── Label + icon ──
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Row(
                  key: ValueKey(label),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isIdle
                          ? fillColor
                          : fillProgress > 0.25
                              ? Colors.white
                              : fillColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: context.textTheme.headlineSmall!.copyWith(
                        color: isIdle
                            ? fillColor
                            : fillProgress > 0.25
                                ? Colors.white
                                : fillColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the left→right progress fill with an optional shimmer sweep.
class _WaveFillPainter extends CustomPainter {
  final double progress;   // 0.0 → 1.0
  final Color fillColor;
  final double shimmerPos; // normalised x: -0.4 → 1.4

  const _WaveFillPainter({
    required this.progress,
    required this.fillColor,
    required this.shimmerPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillW = size.width * progress.clamp(0.0, 1.0);

    // Solid fill
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, fillW, size.height), fillPaint);

    // Shimmer stripe (only within filled area)
    if (shimmerPos > -1.0 && progress < 1.0) {
      final centerX = shimmerPos * size.width;
      const halfWidth = 56.0;
      final left = (centerX - halfWidth).clamp(0.0, fillW);
      final right = (centerX + halfWidth).clamp(0.0, fillW);
      if (right > left) {
        final shimmerPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(left, 0, right - left, size.height));
        canvas.drawRect(
          Rect.fromLTWH(left, 0, right - left, size.height),
          shimmerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WaveFillPainter old) =>
      old.progress != progress ||
      old.shimmerPos != shimmerPos ||
      old.fillColor != fillColor;
}
