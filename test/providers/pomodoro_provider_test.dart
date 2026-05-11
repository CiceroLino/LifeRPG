import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/repositories/player_repository.dart';
import 'package:liferpg/providers/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
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
}
