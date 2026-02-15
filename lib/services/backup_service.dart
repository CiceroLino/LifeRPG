import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../data/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> createBackupFile() async {
    try {
      final backupData = await _dbHelper.getAllDataForBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final fileName = 'liferpg_backup_$timestamp.json';

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath == null) {
          return false;
        }

        final file = File(outputPath);
        await file.writeAsString(jsonString);

        return true;
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);

        final result = await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'LifeRPG Backup',
          text: 'LifeRPG backup created on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
        );

        return result.status == ShareResultStatus.success;
      }
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
      );

      if (result == null || result.files.single.path == null) {
        return BackupRestoreResult(
          success: false,
          message: 'No file selected',
        );
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
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

  bool _validateBackupStructure(Map<String, dynamic> data) {
    if (!data.containsKey('version')) return false;
    if (!data.containsKey('player')) return false;
    if (!data.containsKey('missions')) return false;
    if (!data.containsKey('skills')) return false;

    return true;
  }

  Future<BackupInfo> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final missionsCount = (data['missions'] as List?)?.length ?? 0;
      final skillsCount = (data['skills'] as List?)?.length ?? 0;
      final timestamp = data['timestamp'] as String?;

      return BackupInfo(
        isValid: _validateBackupStructure(data),
        version: data['version'] as String? ?? 'unknown',
        timestamp: timestamp != null ? DateTime.parse(timestamp) : null,
        missionsCount: missionsCount,
        skillsCount: skillsCount,
      );
    } catch (e) {
      return BackupInfo(
        isValid: false,
        version: 'unknown',
        missionsCount: 0,
        skillsCount: 0,
      );
    }
  }
}

class BackupRestoreResult {
  final bool success;
  final String message;

  BackupRestoreResult({
    required this.success,
    required this.message,
  });
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
