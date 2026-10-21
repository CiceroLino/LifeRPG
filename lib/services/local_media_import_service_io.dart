import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'local_media_import_service_base.dart';

const localMediaImportSupported = true;

LocalMediaImportService createLocalMediaImportService({String? basePath}) {
  return IoLocalMediaImportService(basePath: basePath);
}

class IoLocalMediaImportService implements LocalMediaImportService {
  IoLocalMediaImportService({String? basePath}) : _basePath = basePath;

  final String? _basePath;

  @override
  Future<ImportedMediaFile> importPlatformFile(
    PlatformFile file, {
    required LocalMediaLibrary library,
    required List<String> allowedExtensions,
  }) async {
    final originalName = _sanitizeFileName(file.name, fallback: 'imported');
    _validateExtension(originalName, file.extension, allowedExtensions);

    final stream = file.readStream;
    if (stream != null) {
      return _copyStream(stream, originalName: originalName, library: library);
    }

    final bytes = file.bytes;
    if (bytes != null) {
      return _copyBytes(bytes, originalName: originalName, library: library);
    }

    final sourcePath = file.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      throw const LocalMediaImportException(
        'The selected file did not provide readable data.',
      );
    }

    return importFilePath(
      sourcePath,
      library: library,
      allowedExtensions: allowedExtensions,
      originalName: originalName,
    );
  }

  @override
  Future<ImportedMediaFile> importFilePath(
    String sourcePath, {
    required LocalMediaLibrary library,
    required List<String> allowedExtensions,
    String? originalName,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw LocalMediaImportException('File not found: $sourcePath');
    }

    final name = _sanitizeFileName(
      originalName ?? p.basename(sourcePath),
      fallback: 'imported',
    );
    _validateExtension(name, p.extension(sourcePath), allowedExtensions);

    return _copyStream(source.openRead(), originalName: name, library: library);
  }

  @override
  Future<bool> isManagedPath(String filePath) async {
    final root = await _rootDirectory();
    final normalizedRoot = p.normalize(root.path);
    final normalizedPath = p.normalize(filePath);
    return p.equals(normalizedRoot, normalizedPath) ||
        p.isWithin(normalizedRoot, normalizedPath);
  }

  @override
  Future<void> discardImport(ImportedMediaFile file) async {
    if (!await isManagedPath(file.path)) return;
    final parent = Directory(p.dirname(file.path));
    if (!p.basename(parent.path).startsWith('import_')) return;
    if (await parent.exists()) await parent.delete(recursive: true);
  }

  Future<ImportedMediaFile> _copyBytes(
    List<int> bytes, {
    required String originalName,
    required LocalMediaLibrary library,
  }) async {
    return _copyStream(
      Stream.value(bytes),
      originalName: originalName,
      library: library,
    );
  }

  Future<ImportedMediaFile> _copyStream(
    Stream<List<int>> stream, {
    required String originalName,
    required LocalMediaLibrary library,
  }) async {
    final directory = await _libraryDirectory(library);
    // createTemp reserves a distinct directory atomically, including across processes.
    final reservation = await directory.createTemp('import_');
    final target = File(p.join(reservation.path, originalName));
    final pending = File(p.join(reservation.path, '.partial'));
    final sink = pending.openWrite();
    var size = 0;

    try {
      await for (final chunk in stream) {
        size += chunk.length;
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      await pending.rename(target.path);
    } catch (_) {
      try {
        await sink.close();
      } catch (_) {
        /* retain original copy error */
      }
      await reservation.delete(recursive: true);
      rethrow;
    }

    return _importedFile(target, originalName, size);
  }

  ImportedMediaFile _importedFile(File target, String originalName, int size) {
    return ImportedMediaFile(
      path: target.path,
      originalName: originalName,
      title: p.basenameWithoutExtension(originalName),
      sizeBytes: size,
    );
  }

  Future<Directory> _libraryDirectory(LocalMediaLibrary library) async {
    final root = await _rootDirectory();
    final directory = Directory(p.join(root.path, library.directoryName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _rootDirectory() async {
    final configured = _basePath;
    if (configured != null && configured.trim().isNotEmpty) {
      final directory = Directory(configured);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }

    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'media'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _sanitizeFileName(String value, {required String fallback}) {
    final basename = p.basename(value).trim();
    final cleaned = basename
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return fallback;
    }
    return cleaned;
  }

  void _validateExtension(
    String fileName,
    String? fallbackExtension,
    List<String> allowedExtensions,
  ) {
    final allowed = allowedExtensions
        .map((extension) => extension.toLowerCase().replaceFirst('.', ''))
        .toSet();
    final extension =
        (p.extension(fileName).isNotEmpty
                ? p.extension(fileName)
                : fallbackExtension ?? '')
            .toLowerCase()
            .replaceFirst('.', '');

    if (extension.isEmpty || !allowed.contains(extension)) {
      throw LocalMediaImportException(
        'Unsupported file extension: ${extension.isEmpty ? fileName : extension}',
      );
    }
  }
}
