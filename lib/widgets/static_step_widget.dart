import 'package:flutter/material.dart';
import '../models/step_model.dart';
import 'app_image.dart';
import 'app_theme.dart';
import 'step_block_widget.dart';

class StaticStepWidget extends StatefulWidget {
  final StepModel step;
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;

  const StaticStepWidget({
    super.key,
    required this.step,
    required this.currentIndex,
    required this.totalSteps,
    required this.onNext,
    this.onPrevious,
  });

  @override
  State<StaticStepWidget> createState() => _StaticStepWidgetState();
}

class _StaticStepWidgetState extends State<StaticStepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void didUpdateWidget(StaticStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step image
            if (widget.step.imagePath != null &&
                widget.step.imagePath!.isNotEmpty)
              _buildStepImage(),

            const SizedBox(height: 24),

            // Instruction
            if (widget.step.instruction.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Text(
                  widget.step.instruction,
                  style: context.textTheme.bodyLarge,
                ),
              ),

            const SizedBox(height: 16),

            // Blocks
            if (widget.step.blocks.isNotEmpty)
              ...widget.step.blocks.map((b) => StepBlockWidget(block: b)),

            const Spacer(),

            // Navigation buttons
            _buildNavButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStepImage() {
    return AppImage(
      imagePath: widget.step.imagePath,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(16),
      placeholder: const SizedBox.shrink(),
    );
  }

  Widget _buildNavButtons(BuildContext context) {
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
            onPressed: widget.onNext,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              widget.currentIndex == widget.totalSteps - 1
                  ? 'Hoàn thành'
                  : 'Tiếp tục',
              style: context.textTheme.labelLarge!.copyWith(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
