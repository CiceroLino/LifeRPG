import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:liferpg/services/local_media_import_service.dart';

void main() {
  late Directory tempDir;
  late LocalMediaImportService importer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('liferpg_media_test_');
    importer = createLocalMediaImportService(basePath: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('copies picked PDF stream into managed tome storage', () async {
    final file = PlatformFile(
      name: 'Arcane Guide.pdf',
      size: 5,
      readStream: Stream.value([1, 2, 3, 4, 5]),
    );

    final imported = await importer.importPlatformFile(
      file,
      library: LocalMediaLibrary.tomes,
      allowedExtensions: const ['pdf'],
    );

    expect(imported.title, 'Arcane Guide');
    expect(imported.originalName, 'Arcane Guide.pdf');
    expect(imported.path, contains('${Platform.pathSeparator}tomes'));
    expect(await File(imported.path).readAsBytes(), [1, 2, 3, 4, 5]);
    expect(await importer.isManagedPath(imported.path), isTrue);
  });

  test(
    'copies source path into managed audio storage with collision suffix',
    () async {
      final source = File('${tempDir.path}${Platform.pathSeparator}song.mp3');
      await source.writeAsBytes([7, 8, 9]);

      final first = await importer.importFilePath(
        source.path,
        library: LocalMediaLibrary.tavern,
        allowedExtensions: const ['mp3'],
      );
      final second = await importer.importFilePath(
        source.path,
        library: LocalMediaLibrary.tavern,
        allowedExtensions: const ['mp3'],
      );

      expect(first.title, 'song');
      expect(second.title, 'song 2');
      expect(first.path, isNot(second.path));
      expect(await File(first.path).readAsBytes(), [7, 8, 9]);
      expect(await File(second.path).readAsBytes(), [7, 8, 9]);
    },
  );

  test('rejects unavailable files before creating metadata', () async {
    final file = PlatformFile(name: 'missing.pdf', size: 0);

    await expectLater(
      () => importer.importPlatformFile(
        file,
        library: LocalMediaLibrary.tomes,
        allowedExtensions: const ['pdf'],
      ),
      throwsA(isA<LocalMediaImportException>()),
    );
  });
}
