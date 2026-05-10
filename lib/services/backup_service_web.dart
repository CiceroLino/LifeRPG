import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> createBackupFile() async {
    try {
      final backupData = await _dbHelper.getAllDataForBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final fileName = 'liferpg_backup_$timestamp.json';

      final result = await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(jsonString),
            name: fileName,
            mimeType: 'application/json',
          ),
        ],
        subject: 'LifeRPG Backup',
        text:
            'LifeRPG backup created on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Erro ao criar backup: $e');
      return false;
    }
  }

  Future<BackupRestoreResult> restoreBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        return BackupRestoreResult(success: false, message: 'No file selected');
      }

      final jsonString = utf8.decode(result.files.single.bytes!);
      Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (_) {
        return BackupRestoreResult(
          success: false,
          message: 'Invalid JSON file format',
        );
      }

      if (!_validateBackupStructure(backupData)) {
        return BackupRestoreResult(
          success: false,
          message: 'Invalid backup file structure',
        );
      }

      await _dbHelper.restoreData(backupData);
      return BackupRestoreResult(
        success: true,
        message: 'Backup restored successfully',
      );
    } catch (e) {
      debugPrint('Erro ao restaurar backup: $e');
      return BackupRestoreResult(
        success: false,
        message: 'Error restoring backup: ${e.toString()}',
      );
    }
  }

  Future<BackupInfo> getBackupInfo(String filePath) async {
    return BackupInfo(
      isValid: false,
      version: 'unknown',
      missionsCount: 0,
      skillsCount: 0,
    );
  }

  bool _validateBackupStructure(Map<String, dynamic> data) {
    if (!data.containsKey('version')) return false;
    if (!data.containsKey('player')) return false;
    if (!data.containsKey('missions')) return false;
    if (!data.containsKey('skills')) return false;
    return true;
  }
}

class BackupRestoreResult {
  final bool success;
  final String message;

  BackupRestoreResult({required this.success, required this.message});
}

class BackupInfo {
  final bool isValid;
  final String version;
  final DateTime? timestamp;
  final int missionsCount;
  final int skillsCount;

  BackupInfo({
    required this.isValid,
    required this.version,
    this.timestamp,
    required this.missionsCount,
    required this.skillsCount,
  });
}
