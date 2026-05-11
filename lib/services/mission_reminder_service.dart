import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/mission.dart';

class MissionReminderService {
  MissionReminderService._();

  static final MissionReminderService instance = MissionReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ),
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleForMission(
    Mission mission, {
    required bool notificationsEnabled,
  }) async {
    if (mission.id == null) return;
    await cancelForMission(mission.id!);
    final reminderAt = mission.reminderAt;
    if (!notificationsEnabled || reminderAt == null) return;
    if (!reminderAt.isAfter(DateTime.now())) return;
    if (kIsWeb) return;

    await initialize();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mission_reminders',
        'Mission reminders',
        channelDescription: 'LifeRPG mission reminder alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId(mission.id!),
      title: 'LifeRPG Mission',
      body: mission.title,
      scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'mission:${mission.id}',
    );
  }

  Future<void> cancelForMission(int missionId) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: _notificationId(missionId));
  }

  int _notificationId(int missionId) => 100000 + missionId;
}
