import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/mission.dart';
import 'reminder_backend.dart';
export 'reminder_backend.dart';

enum ReminderScheduleResult {
  scheduled,
  disabled,
  noReminder,
  unsupported,
  permissionDenied,
  failed,
}

class ReminderPreferences {
  const ReminderPreferences({required this.enabled, this.soundEnabled = true});
  final bool enabled;
  final bool soundEnabled;
}

class MissionReminderService {
  MissionReminderService({
    ReminderBackend? backend,
    Future<ReminderPreferences> Function()? readPreferences,
  }) : _backend = backend ?? PlatformReminderBackend(),
       _readPreferences = readPreferences ?? _storedPreferences;
  static final instance = MissionReminderService();
  final ReminderBackend _backend;
  final Future<ReminderPreferences> Function() _readPreferences;
  Future<void>? _initialization;
  Future<void> _tail = Future.value();
  bool _available = false;
  String? lastWarning;
  bool get isAvailable => _available;

  static Future<ReminderPreferences> _storedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderPreferences(
      enabled: prefs.getBool('notifications_enabled') ?? true,
      soundEnabled: prefs.getBool('notification_sounds_enabled') ?? true,
    );
  }

  Future<T> _run<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    try {
      _available = await _backend.initialize();
    } catch (error) {
      _available = false;
      debugPrint('Notifications are unavailable: $error');
    }
  }

  Future<bool> requestPermissions() => _run(_requestPermissions);
  Future<bool> _requestPermissions() async {
    await initialize();
    if (!_available || !_backend.supportsScheduling) {
      lastWarning = 'Scheduled reminders are unavailable on this device.';
      return false;
    }
    final allowed = await _backend.requestPermissions();
    lastWarning = allowed ? null : 'Notification permission was not granted.';
    return allowed;
  }

  Future<ReminderScheduleResult> scheduleForMission(
    Mission mission, {
    bool notificationsEnabled = true,
  }) => _run(
    () => _schedule(mission, notificationsEnabled: notificationsEnabled),
  );

  Future<ReminderScheduleResult> _schedule(
    Mission mission, {
    bool notificationsEnabled = true,
    bool requestPermission = true,
  }) async {
    lastWarning = null;
    if (mission.id == null) return ReminderScheduleResult.noReminder;
    try {
      await initialize();
      if (_available) await _backend.cancel(mission.id!);
      if (mission.status != 'active' ||
          mission.reminderAt == null ||
          !mission.reminderAt!.isAfter(DateTime.now())) {
        return ReminderScheduleResult.noReminder;
      }
      final prefs = await _readPreferences();
      if (!notificationsEnabled || !prefs.enabled)
        return ReminderScheduleResult.disabled;
      if (!_available || !_backend.supportsScheduling) {
        lastWarning =
            'The mission was saved. Scheduled reminders are unavailable on this device.';
        return ReminderScheduleResult.unsupported;
      }
      if (requestPermission && !await _requestPermissions())
        return ReminderScheduleResult.permissionDenied;
      await _backend.schedule(mission, soundEnabled: prefs.soundEnabled);
      return ReminderScheduleResult.scheduled;
    } catch (error) {
      lastWarning =
          'The mission was saved, but its reminder could not be scheduled.';
      debugPrint('Reminder scheduling failed: $error');
      return ReminderScheduleResult.failed;
    }
  }

  Future<void> cancelForMission(int id) => _run(() async {
    await initialize();
    if (_available) await _backend.cancel(id);
  });

  Future<void> cancelAll() => _run(() async {
    await initialize();
    if (_available) await _backend.cancelAll();
  });

  Future<void> reconcile(Iterable<Mission> missions) {
    final snapshot = missions.toList(growable: false);
    return _run(() async {
      await initialize();
      if (_available) await _backend.cancelAll();
      for (final mission in snapshot) {
        await _schedule(mission, requestPermission: false);
      }
    });
  }
}
