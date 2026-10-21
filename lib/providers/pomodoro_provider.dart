import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../services/focus_session_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final FocusSessionService _service;
  final Future<void> Function()? _onCompleted;
  String? _sessionKey;
  String? _error;
  bool _disposed = false;

  int _plannedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  DateTime? _startedAt;
  Timer? _timer;
  bool _isCompleting = false;

  PomodoroProvider({
    FocusSessionService? service,
    Future<void> Function()? onCompleted,
  }) : _service = service ?? FocusSessionService(),
       _onCompleted = onCompleted;

  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

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
    _notify();
  }

  void start() {
    if (isRunning) return;
    _startedAt ??= DateTime.now();
    _sessionKey ??= const Uuid().v4();
    _error = null;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        unawaited(_completeAutomatically());
        return;
      }
      _remainingSeconds -= 1;
      _notify();
    });
    _notify();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _notify();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    _sessionKey = null;
    _error = null;
    _remainingSeconds = _plannedMinutes * 60;
    _notify();
  }

  Future<FocusSessionResult?> completeNow() async {
    if (_isCompleting) return null;
    _isCompleting = true;
    _sessionKey ??= const Uuid().v4();
    _timer?.cancel();
    _timer = null;
    _notify();

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
        sessionKey: _sessionKey,
      );
      _startedAt = null;
      _sessionKey = null;
      _error = null;
      _remainingSeconds = _plannedMinutes * 60;
      if (!_disposed) await _onCompleted?.call();
      return result;
    } finally {
      _isCompleting = false;
      _notify();
    }
  }

  Future<void> _completeAutomatically() async {
    try {
      await completeNow();
    } catch (error) {
      _error = 'Unable to save focus session: $error';
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
