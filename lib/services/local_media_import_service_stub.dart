import 'local_media_import_service_base.dart';
import 'package:file_picker/file_picker.dart';

const localMediaImportSupported = false;

LocalMediaImportService createLocalMediaImportService({String? basePath}) {
  return _UnavailableMediaImport();
}

class _UnavailableMediaImport implements LocalMediaImportService {
  @override
  Future<ImportedMediaFile> importPlatformFile(
    PlatformFile file, {
    required LocalMediaLibrary library,
    required List<String> allowedExtensions,
  }) async => throw const LocalMediaImportException(
    'File import is unavailable in this browser.',
  );

  @override
  Future<ImportedMediaFile> importFilePath(
    String sourcePath, {
    required LocalMediaLibrary library,
    required List<String> allowedExtensions,
    String? originalName,
  }) async => throw const LocalMediaImportException(
    'File import is unavailable in this browser.',
  );

  @override
  Future<bool> isManagedPath(String filePath) async => false;
}
