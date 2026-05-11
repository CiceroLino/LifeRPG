import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/repositories/focus_session_repository.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/services/focus_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FocusSessionService service;
  late FocusSessionRepository sessions;
  late PlayerRepository players;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    service = FocusSessionService();
    sessions = FocusSessionRepository();
    players = PlayerRepository();
  });

  test('completed focus session grants one XP per minute and records history', () async {
    final result = await service.completeSession(
      plannedMinutes: 25,
      completedMinutes: 25,
    );

    expect(result.xpGranted, 25);
    expect((await players.get()).totalXP, 25);

    final history = await sessions.getRecent();
    expect(history, hasLength(1));
    expect(history.single.plannedMinutes, 25);
    expect(history.single.completedMinutes, 25);
    expect(history.single.xpGranted, 25);
    expect(history.single.status, 'completed');
  });

  test('focus sessions cannot exceed four hours', () async {
    expect(
      () => service.completeSession(plannedMinutes: 241, completedMinutes: 241),
      throwsA(isA<FocusSessionLimitException>()),
    );
  });

  test('backup and restore preserve focus session history', () async {
    await service.completeSession(plannedMinutes: 45, completedMinutes: 45);

    final backup = await DatabaseHelper().getAllDataForBackup();
    await DatabaseHelper().resetForTesting();
    expect(await sessions.getRecent(), isEmpty);

    await DatabaseHelper().restoreData(backup);

    final restored = await sessions.getRecent();
    expect(restored, hasLength(1));
    expect(restored.single.plannedMinutes, 45);
    expect(restored.single.xpGranted, 45);
    expect((await players.get()).totalXP, 45);
  });
}
