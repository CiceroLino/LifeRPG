import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/providers/settings_provider.dart';
import 'package:liferpg/services/mission_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/test_database.dart';

class _Backend implements ReminderBackend {
  bool allowed = true;
  @override
  bool supportsScheduling = true;
  final pending = <int>{};
  int requests = 0;
  bool? sound;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<bool> hasPermission() async => allowed;
  @override
  Future<bool> requestPermissions() async {
    requests++;
    return allowed;
  }

  @override
  Future<void> cancel(int id) async {
    pending.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    pending.clear();
  }

  @override
  Future<void> schedule(Mission mission, {required bool soundEnabled}) async {
    if (!supportsScheduling) throw UnsupportedError('unsupported');
    pending.add(mission.id!);
    sound = soundEnabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await resetTestDatabase();
    SharedPreferences.setMockInitialValues({});
  });
  Mission reminder({int id = 1}) => Mission(
    id: id,
    title: 'Remember',
    reminderAt: DateTime.now().add(const Duration(days: 1)),
  );

  test(
    'disabled preferences override an explicit true scheduling hint',
    () async {
      final backend = _Backend()..pending.add(1);
      final service = MissionReminderService(
        backend: backend,
        readPreferences: () async => const ReminderPreferences(enabled: false),
      );
      expect(
        await service.scheduleForMission(
          reminder(),
          notificationsEnabled: true,
        ),
        ReminderScheduleResult.disabled,
      );
      expect(backend.pending, isEmpty);
    },
  );
  test(
    'permission refusal is represented without pretending to schedule',
    () async {
      final backend = _Backend()..allowed = false;
      final service = MissionReminderService(
        backend: backend,
        readPreferences: () async => const ReminderPreferences(enabled: true),
      );
      expect(
        await service.scheduleForMission(reminder()),
        ReminderScheduleResult.permissionDenied,
      );
      expect(backend.requests, 1);
      expect(backend.pending, isEmpty);
      expect(service.lastWarning, isNotNull);
    },
  );
  test(
    'reconciliation retains denial and aggregates warnings across missions',
    () async {
      final backend = _Backend()..allowed = false;
      final service = MissionReminderService(
        backend: backend,
        readPreferences: () async => const ReminderPreferences(enabled: true),
      );
      final provider = MissionProvider(reminders: service);
      await provider.addMission(reminder().copyWith(id: null));
      expect(backend.pending, isEmpty);
      expect(provider.warning, contains('permission'));
      await service.reconcile([reminder(), Mission(id: 2, title: 'No alert')]);
      expect(service.lastWarning, contains('permission'));
      expect(backend.pending, isEmpty);
      expect(backend.requests, 1);
      provider.dispose();
    },
  );

  test(
    'unsupported warning survives a later mission without reminder',
    () async {
      final backend = _Backend()..supportsScheduling = false;
      final service = MissionReminderService(backend: backend);
      await service.reconcile([reminder(), Mission(id: 2, title: 'No alert')]);
      expect(service.lastWarning, contains('unavailable'));
    },
  );

  test(
    'startup reconciliation reads OS permission without prompting',
    () async {
      final backend = _Backend()..allowed = false;
      final service = MissionReminderService(
        backend: backend,
        readPreferences: () async => const ReminderPreferences(enabled: true),
      );
      await service.reconcile([reminder()]);
      expect(backend.pending, isEmpty);
      expect(service.lastWarning, contains('permission'));
      backend.allowed = true;
      await service.reconcile([reminder()]);
      expect(backend.pending, {1});
      expect(backend.requests, 0);
    },
  );

  test('turning notifications off cancels alerts already scheduled', () async {
    final backend = _Backend();
    final service = MissionReminderService(backend: backend);
    final settings = SettingsProvider(reminders: service);
    await settings.initialize();
    await service.scheduleForMission(reminder());
    expect(backend.pending, {1});
    await settings.setNotificationsEnabled(false);
    expect(backend.pending, isEmpty);
    expect(settings.notificationsEnabled, isFalse);
    settings.dispose();
  });
  test('a recurring completion cannot re-enable disabled reminders', () async {
    final backend = _Backend();
    final service = MissionReminderService(
      backend: backend,
      readPreferences: () async => const ReminderPreferences(enabled: false),
    );
    final provider = MissionProvider(reminders: service);
    final id = await MissionRepository().insert(
      Mission(
        title: 'Again',
        isRecurring: true,
        recurrenceType: 'continuous',
        reminderAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await provider.completeMission(id);
    expect(backend.pending, isEmpty);
    expect(provider.missions.single.streak, 1);
    provider.dispose();
  });
  test(
    'unsupported scheduling does not undo or hide a saved mission',
    () async {
      final backend = _Backend()..supportsScheduling = false;
      final provider = MissionProvider(
        reminders: MissionReminderService(backend: backend),
      );
      final id = await provider.addMission(
        Mission(
          title: 'Linux quest',
          reminderAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      expect(id, isNotNull);
      expect(provider.missions.single.title, 'Linux quest');
      expect(provider.warning, isNotNull);
      expect(provider.error, isNull);
      provider.dispose();
    },
  );
  test('notification sound preference reaches the scheduled alert', () async {
    final backend = _Backend();
    final service = MissionReminderService(
      backend: backend,
      readPreferences: () async =>
          const ReminderPreferences(enabled: true, soundEnabled: false),
    );
    await service.scheduleForMission(reminder());
    expect(backend.sound, isFalse);
  });
  test(
    'Windows configuration is supplied to the native initialization boundary',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        var initialized = false;
        final backend = PlatformReminderBackend(
          initializePlugin: (settings) async {
            expect(settings.windows, isNotNull);
            expect(settings.windows!.appName, 'LifeRPG');
            expect(settings.windows!.guid, isNotEmpty);
            initialized = true;
            return true;
          },
        );
        expect(await backend.initialize(), isTrue);
        expect(initialized, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  test(
    'deleting a parent cancels reminders belonging to cascade-deleted children',
    () async {
      final backend = _Backend();
      final service = MissionReminderService(backend: backend);
      final provider = MissionProvider(reminders: service);
      final repo = MissionRepository();
      final parent = await repo.insert(Mission(title: 'Parent'));
      final child = await repo.insert(
        Mission(
          title: 'Child',
          parentMissionId: parent,
          reminderAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      backend.pending.addAll([parent, child]);
      await provider.deleteMission(parent);
      expect(backend.pending, isEmpty);
      expect(provider.missions, isEmpty);
      provider.dispose();
    },
  );
}
