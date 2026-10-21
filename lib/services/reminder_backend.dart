import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/mission.dart';

abstract class ReminderBackend {
  bool get supportsScheduling;
  Future<bool> initialize();
  Future<bool> requestPermissions();
  Future<void> schedule(Mission mission, {required bool soundEnabled});
  Future<void> cancel(int missionId);
  Future<void> cancelAll();
}

class PlatformReminderBackend implements ReminderBackend {
  PlatformReminderBackend({
    Future<bool?> Function(InitializationSettings)? initializePlugin,
  }) : _initializePlugin = initializePlugin;
  final Future<bool?> Function(InitializationSettings)? _initializePlugin;
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  bool get supportsScheduling =>
      !kIsWeb &&
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }.contains(defaultTargetPlatform);

  @override
  Future<bool> initialize() async {
    if (!supportsScheduling) return false;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      windows: WindowsInitializationSettings(
        appName: 'LifeRPG',
        appUserModelId: 'LifeRPG.Desktop',
        guid: 'c81a1a1e-7e55-4bad-a9a3-9d45c491d0a2',
      ),
    );
    return await (_initializePlugin?.call(settings) ??
            _plugin.initialize(settings: settings)) ??
        false;
  }

  @override
  Future<bool> requestPermissions() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      case TargetPlatform.macOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      case TargetPlatform.windows:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<void> schedule(Mission mission, {required bool soundEnabled}) async {
    await _plugin.zonedSchedule(
      id: 100000 + mission.id!,
      title: 'LifeRPG Mission',
      body: mission.title,
      scheduledDate: tz.TZDateTime.from(mission.reminderAt!, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          soundEnabled ? 'mission_reminders_sound' : 'mission_reminders_silent',
          'Mission reminders',
          channelDescription: 'LifeRPG mission reminder alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: soundEnabled,
        ),
        iOS: DarwinNotificationDetails(presentSound: soundEnabled),
        macOS: DarwinNotificationDetails(presentSound: soundEnabled),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'mission:${mission.id}',
    );
  }

  @override
  Future<void> cancel(int missionId) => _plugin.cancel(id: 100000 + missionId);

  @override
  Future<void> cancelAll() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload?.startsWith('mission:') ?? false) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }
}
