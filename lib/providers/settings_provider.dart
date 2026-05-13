import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/backup_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyLanguage = 'language';
  static const String _keySoundEffects = 'sound_effects_enabled';
  static const String _keyNotificationSounds = 'notification_sounds_enabled';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyStartWeekOnMonday = 'start_week_on_monday';
  static const String _keyUse24HourFormat = 'use_24_hour_format';
  static const String _keyShowXpBar = 'show_xp_bar';

  final BackupService _backupService = BackupService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  SharedPreferences? _prefs;
  bool _isLoading = true;

  String _language = 'en';
  bool _soundEffectsEnabled = false;
  bool _notificationSoundsEnabled = true;
  bool _notificationsEnabled = true;
  bool _startWeekOnMonday = false;
  bool _use24HourFormat = false;
  bool _showXpBar = true;

  bool get isLoading => _isLoading;
  String get language => _language;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get notificationSoundsEnabled => _notificationSoundsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get startWeekOnMonday => _startWeekOnMonday;
  bool get use24HourFormat => _use24HourFormat;
  bool get showXpBar => _showXpBar;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      _loadSettings();
    } catch (e) {
      debugPrint('Erro ao inicializar configurações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadSettings() {
    if (_prefs == null) return;

    _language = AppLocalizations.normalizeLanguageCode(
      _prefs!.getString(_keyLanguage) ?? 'en',
    );
    if (_prefs!.getString(_keyLanguage) != _language) {
      _prefs!.setString(_keyLanguage, _language);
    }
    _soundEffectsEnabled = _prefs!.getBool(_keySoundEffects) ?? false;
    _notificationSoundsEnabled =
        _prefs!.getBool(_keyNotificationSounds) ?? true;
    _notificationsEnabled = _prefs!.getBool(_keyNotifications) ?? true;
    _startWeekOnMonday = _prefs!.getBool(_keyStartWeekOnMonday) ?? false;
    _use24HourFormat = _prefs!.getBool(_keyUse24HourFormat) ?? false;
    _showXpBar = _prefs!.getBool(_keyShowXpBar) ?? true;
  }

  Future<void> setLanguage(String value) async {
    final normalized = AppLocalizations.normalizeLanguageCode(value);
    if (_language == normalized) return;
    _language = normalized;
    await _prefs?.setString(_keyLanguage, normalized);
    notifyListeners();
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    if (_soundEffectsEnabled == value) return;
    _soundEffectsEnabled = value;
    await _prefs?.setBool(_keySoundEffects, value);
    notifyListeners();
  }

  Future<void> setNotificationSoundsEnabled(bool value) async {
    if (_notificationSoundsEnabled == value) return;
    _notificationSoundsEnabled = value;
    await _prefs?.setBool(_keyNotificationSounds, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    await _prefs?.setBool(_keyNotifications, value);
    notifyListeners();
  }

  Future<void> setStartWeekOnMonday(bool value) async {
    if (_startWeekOnMonday == value) return;
    _startWeekOnMonday = value;
    await _prefs?.setBool(_keyStartWeekOnMonday, value);
    notifyListeners();
  }

  Future<void> setUse24HourFormat(bool value) async {
    if (_use24HourFormat == value) return;
    _use24HourFormat = value;
    await _prefs?.setBool(_keyUse24HourFormat, value);
    notifyListeners();
  }

  Future<void> setShowXpBar(bool value) async {
    if (_showXpBar == value) return;
    _showXpBar = value;
    await _prefs?.setBool(_keyShowXpBar, value);
    notifyListeners();
  }

  Future<bool> exportData() async {
    try {
      final success = await _backupService.createBackupFile();
      if (!success) {
        debugPrint('Falha ao criar arquivo de backup');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao exportar dados: $e');
      return false;
    }
  }

  Future<String> importData() async {
    try {
      final result = await _backupService.restoreBackupFile();
      return result.message;
    } catch (e) {
      debugPrint('Erro ao importar dados: $e');
      return 'Error: ${e.toString()}';
    }
  }

  Future<void> resetCharacter() async {
    await _dbHelper.resetCharacterStats();
  }

  Future<void> factoryReset() async {
    await _dbHelper.factoryReset();

    if (_prefs != null) {
      await _prefs!.clear();
    }

    _language = 'en';
    _soundEffectsEnabled = false;
    _notificationSoundsEnabled = true;
    _notificationsEnabled = true;
    _startWeekOnMonday = false;
    _use24HourFormat = false;
    _showXpBar = true;

    await initialize();
  }
}
