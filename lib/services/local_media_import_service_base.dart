import 'package:file_picker/file_picker.dart';

enum LocalMediaLibrary {
  tomes('tomes'),
  tavern('tavern');

  const LocalMediaLibrary(this.directoryName);

  final String directoryName;
}

class ImportedMediaFile {
  const ImportedMediaFile({
    required this.path,
    required this.originalName,
    required this.title,
    required this.sizeBytes,
  });

  final String path;
  final String originalName;
  final String title;
  final int sizeBytes;
}

class LocalMediaImportException implements Exception {
  const LocalMediaImportException(this.message);

  final String message;

  @override
  String toString() => 'LocalMediaImportException: $message';
}

abstract class LocalMediaImportService {
  Future<ImportedMediaFile> importPlatformFile(
    PlatformFile file, {
    required LocalMediaLibrary library,
    required List<String> allowedExtensions,
  });

  Future<ImportedMediaFile> importFilePath(
    String sourcePath, {
    required LocalMediaLibrary library,
    required List<String> allowedExtensions,
    String? originalName,
  });

  Future<bool> isManagedPath(String filePath);
}
