import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/focus_session_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final FocusSessionService _service;

  int _plannedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  DateTime? _startedAt;
  Timer? _timer;
  bool _isCompleting = false;

  PomodoroProvider({FocusSessionService? service})
    : _service = service ?? FocusSessionService();

  int get plannedMinutes => _plannedMinutes;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _timer?.isActive ?? false;
  bool get isCompleting => _isCompleting;

  double get progress {
    final total = _plannedMinutes * 60;
    if (total <= 0) return 0;
    return 1 - (_remainingSeconds / total);
  }

  void setPlannedMinutes(int minutes) {
    final clamped = minutes.clamp(1, FocusSessionService.maxSessionMinutes);
    _plannedMinutes = clamped;
    if (!isRunning) {
      _remainingSeconds = clamped * 60;
    }
    notifyListeners();
  }

  void start() {
    if (isRunning) return;
    _startedAt ??= DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        completeNow();
        return;
      }
      _remainingSeconds -= 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    _remainingSeconds = _plannedMinutes * 60;
    notifyListeners();
  }

  Future<FocusSessionResult?> completeNow() async {
    if (_isCompleting) return null;
    _isCompleting = true;
    _timer?.cancel();
    _timer = null;
    notifyListeners();

    try {
      final elapsedSeconds = (_plannedMinutes * 60 - _remainingSeconds).clamp(
        0,
        _plannedMinutes * 60,
      );
      final completedMinutes = elapsedSeconds == 0
          ? _plannedMinutes
          : (elapsedSeconds / 60).ceil();
      final result = await _service.completeSession(
        plannedMinutes: _plannedMinutes,
        completedMinutes: completedMinutes,
        startedAt: _startedAt,
      );
      _startedAt = null;
      _remainingSeconds = _plannedMinutes * 60;
      return result;
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
