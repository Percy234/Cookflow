import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

enum TimerStatus { idle, running, paused, completed }

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _timer;
  String? _currentStepId;
  String? _currentStepName;
  int _totalSeconds = 0;
  int _secondsRemaining = 0;
  TimerStatus _status = TimerStatus.idle;
  VoidCallback? _onCompleted;
  bool _notificationSent = false;

  // ─── Getters ───────────────────────────────────────────────────
  String? get currentStepId => _currentStepId;
  String? get currentStepName => _currentStepName;
  int get secondsRemaining => _secondsRemaining;
  int get totalSeconds => _totalSeconds;
  TimerStatus get status => _status;
  bool get isRunning => _status == TimerStatus.running;
  bool get isPaused => _status == TimerStatus.paused;
  bool get isCompleted => _status == TimerStatus.completed;
  bool get isIdle => _status == TimerStatus.idle;

  double get progress =>
      _totalSeconds == 0 ? 0 : 1 - (_secondsRemaining / _totalSeconds);

  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── Controls ──────────────────────────────────────────────────

  void init(String stepId, String stepName, int durationSeconds, {VoidCallback? onCompleted}) {
    if (_currentStepId == stepId) {
      // Nếu đã khởi tạo/đang chạy cho chính bước này, không reset bộ đếm giờ
      _onCompleted = onCompleted;
      return;
    }
    _cancelTimer();
    _currentStepId = stepId;
    _currentStepName = stepName;
    _totalSeconds = durationSeconds;
    _secondsRemaining = durationSeconds;
    _status = TimerStatus.idle;
    _onCompleted = onCompleted;
    _notificationSent = false;
    notifyListeners();
  }


  void start(String stepId, String stepName, int durationSeconds, {VoidCallback? onCompleted}) {
    if (_currentStepId == stepId && _status != TimerStatus.idle) {
      _onCompleted = onCompleted;
      if (_status == TimerStatus.paused) {
        resume();
      }
      return;
    }
    _cancelTimer();
    _currentStepId = stepId;
    _currentStepName = stepName;
    _totalSeconds = durationSeconds;
    _secondsRemaining = durationSeconds;
    _status = TimerStatus.running;
    _onCompleted = onCompleted;
    _notificationSent = false;
    notifyListeners();
    _runTimer();
  }

  void pause() {
    if (_status != TimerStatus.running) return;
    _cancelTimer();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != TimerStatus.paused) return;
    _status = TimerStatus.running;
    notifyListeners();
    _runTimer();
  }

  void reset() {
    _cancelTimer();
    _secondsRemaining = _totalSeconds;
    _status = TimerStatus.idle;
    _notificationSent = false;
    notifyListeners();
  }

  void stop() {
    _cancelTimer();
    _totalSeconds = 0;
    _secondsRemaining = 0;
    _status = TimerStatus.idle;
    _onCompleted = null;
    _currentStepId = null;
    _currentStepName = null;
    _notificationSent = false;
    notifyListeners();
  }

  // ─── Internal ──────────────────────────────────────────────────

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        _cancelTimer();
        _status = TimerStatus.completed;
        notifyListeners();
        _onCompleted?.call();
        _triggerNotification();
        return;
      }
      _secondsRemaining--;
      notifyListeners();
    });
  }

  void _triggerNotification() {
    if (!_notificationSent) {
      _notificationSent = true;
      NotificationService().showTimerCompleteNotification(
        stepName: _currentStepName ?? 'Bước nấu',
      );
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
