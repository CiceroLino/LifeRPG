import '../data/models/focus_session.dart';
import '../data/repositories/focus_session_repository.dart';
import '../data/repositories/player_repository.dart';

class FocusSessionLimitException implements Exception {
  final String message;

  const FocusSessionLimitException(this.message);

  @override
  String toString() => message;
}

class FocusSessionResult {
  final int sessionId;
  final int xpGranted;

  const FocusSessionResult({required this.sessionId, required this.xpGranted});
}

class FocusSessionService {
  static const int maxSessionMinutes = 240;

  final FocusSessionRepository _sessions;
  final PlayerRepository _players;

  FocusSessionService({
    FocusSessionRepository? sessions,
    PlayerRepository? players,
  }) : _sessions = sessions ?? FocusSessionRepository(),
       _players = players ?? PlayerRepository();

  Future<FocusSessionResult> completeSession({
    required int plannedMinutes,
    required int completedMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final safePlanned = _validateMinutes(plannedMinutes);
    final safeCompleted = _validateMinutes(completedMinutes);
    final xpGranted = safeCompleted;
    final finishedAt = completedAt ?? DateTime.now();
    final started =
        startedAt ?? finishedAt.subtract(Duration(minutes: safeCompleted));

    await _players.addXP(xpGranted);
    final sessionId = await _sessions.insert(
      FocusSession(
        plannedMinutes: safePlanned,
        completedMinutes: safeCompleted,
        xpGranted: xpGranted,
        status: 'completed',
        startedAt: started,
        completedAt: finishedAt,
      ),
    );

    return FocusSessionResult(sessionId: sessionId, xpGranted: xpGranted);
  }

  int _validateMinutes(int minutes) {
    if (minutes < 1) {
      throw const FocusSessionLimitException(
        'Focus sessions must last at least one minute.',
      );
    }
    if (minutes > maxSessionMinutes) {
      throw const FocusSessionLimitException(
        'Focus sessions cannot exceed four hours.',
      );
    }
    return minutes;
  }
}
