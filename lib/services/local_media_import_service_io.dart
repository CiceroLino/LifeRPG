import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'local_media_import_service_base.dart';

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

  Future<ImportedMediaFile> _copyBytes(
    List<int> bytes, {
    required String originalName,
    required LocalMediaLibrary library,
  }) async {
    final target = await _uniqueTargetFile(library, originalName);
    await target.writeAsBytes(bytes, flush: true);
    return _importedFile(target, originalName, bytes.length);
  }

  Future<ImportedMediaFile> _copyStream(
    Stream<List<int>> stream, {
    required String originalName,
    required LocalMediaLibrary library,
  }) async {
    final target = await _uniqueTargetFile(library, originalName);
    final sink = target.openWrite();
    var size = 0;

    try {
      await for (final chunk in stream) {
        size += chunk.length;
        sink.add(chunk);
      }
      await sink.close();
    } catch (_) {
      await sink.close();
      if (await target.exists()) {
        await target.delete();
      }
      rethrow;
    }

    return _importedFile(target, originalName, size);
  }

  ImportedMediaFile _importedFile(File target, String originalName, int size) {
    return ImportedMediaFile(
      path: target.path,
      originalName: originalName,
      title: p.basenameWithoutExtension(target.path),
      sizeBytes: size,
    );
  }

  Future<File> _uniqueTargetFile(
    LocalMediaLibrary library,
    String originalName,
  ) async {
    final directory = await _libraryDirectory(library);
    final extension = p.extension(originalName);
    final baseName = p.basenameWithoutExtension(originalName).trim();
    var target = File(p.join(directory.path, '$baseName$extension'));
    var suffix = 2;

    while (await target.exists()) {
      target = File(p.join(directory.path, '$baseName $suffix$extension'));
      suffix += 1;
    }

    return target;
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
