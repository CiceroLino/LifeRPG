class BackupService {
  Future<bool> createBackupFile() async => false;

  Future<BackupRestoreResult> restoreBackupFile() async {
    return BackupRestoreResult(
      success: false,
      message: 'Backup is not supported on this platform',
    );
  }

  Future<BackupInfo> getBackupInfo(String filePath) async {
    return BackupInfo(
      isValid: false,
      version: 'unknown',
      missionsCount: 0,
      skillsCount: 0,
    );
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
