import '../support/test_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/providers/pomodoro_provider.dart';
import 'package:liferpg/services/focus_session_service.dart';

class _ImmediateFocusService extends FocusSessionService {
  @override
  Future<FocusSessionResult> completeSession({
    required int plannedMinutes,
    required int completedMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
    String? sessionKey,
  }) async => FocusSessionResult(sessionId: 1, xpGranted: completedMinutes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await resetTestDatabase();
  });

  test('duration selection is clamped to the four hour focus cap', () {
    final provider = PomodoroProvider();

    provider.setPlannedMinutes(300);

    expect(provider.plannedMinutes, 240);
    expect(provider.remainingSeconds, 240 * 60);
  });

  test('manual completion grants XP and resets the timer', () async {
    final provider = PomodoroProvider();
    provider.setPlannedMinutes(30);

    final result = await provider.completeNow();

    expect(result!.xpGranted, 30);
    expect(provider.remainingSeconds, 30 * 60);
    expect(provider.isRunning, isFalse);
    expect((await PlayerRepository().get()).totalXP, 30);
  });

  testWidgets('automatic completion publishes the player refresh event', (
    tester,
  ) async {
    var refreshes = 0;
    final provider = PomodoroProvider(
      service: _ImmediateFocusService(),
      onCompleted: () async {
        refreshes++;
      },
    );
    provider.setPlannedMinutes(1);
    provider.start();
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(refreshes, 1);
    expect(provider.isRunning, isFalse);
    expect(provider.remainingSeconds, 60);
    provider.dispose();
  });
}
