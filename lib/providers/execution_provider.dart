import 'package:flutter/foundation.dart';
import '../models/step_model.dart';

class ExecutionProvider extends ChangeNotifier {
  List<StepModel> _steps = [];
  int _currentIndex = 0;
  bool _isCompleted = false;

  // ─── Getters ───────────────────────────────────────────────────
  List<StepModel> get steps => _steps;
  int get currentIndex => _currentIndex;
  bool get isCompleted => _isCompleted;
  int get totalSteps => _steps.length;

  StepModel? get currentStep =>
      _steps.isNotEmpty && _currentIndex < _steps.length
          ? _steps[_currentIndex]
          : null;

  bool get hasNext => _currentIndex < _steps.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // ─── Actions ───────────────────────────────────────────────────

  void startExecution(List<StepModel> steps) {
    _steps = steps;
    _currentIndex = 0;
    _isCompleted = false;
    notifyListeners();
  }

  void nextStep() {
    if (_isCompleted) return;
    if (_currentIndex < _steps.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      _isCompleted = true;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _isCompleted = false;
      notifyListeners();
    }
  }

  void reset() {
    _steps = [];
    _currentIndex = 0;
    _isCompleted = false;
    notifyListeners();
  }
}
