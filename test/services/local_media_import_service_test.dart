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
    'copies source path into managed audio storage without overwriting',
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
      expect(second.title, 'song');
      expect(first.path, isNot(second.path));
      expect(await File(first.path).readAsBytes(), [7, 8, 9]);
      expect(await File(second.path).readAsBytes(), [7, 8, 9]);
    },
  );

  test('concurrent homonymous imports preserve every byte stream', () async {
    final imported = await Future.wait(
      List.generate(
        40,
        (i) => importer.importPlatformFile(
          PlatformFile(
            name: i.isEven ? 'same?.pdf' : 'same*.pdf',
            size: 2,
            readStream: Stream.value([i, 255 - i]),
          ),
          library: LocalMediaLibrary.tomes,
          allowedExtensions: ['pdf'],
        ),
      ),
    );
    expect(imported.map((f) => f.path).toSet(), hasLength(40));
    for (var i = 0; i < imported.length; i++) {
      expect(await File(imported[i].path).readAsBytes(), [i, 255 - i]);
    }
  });

  test('interrupted stream leaves no partial published file', () async {
    Stream<List<int>> broken() async* {
      yield [1];
      throw StateError('Interrupted');
    }

    await expectLater(
      importer.importPlatformFile(
        PlatformFile(name: 'broken.pdf', size: 2, readStream: broken()),
        library: LocalMediaLibrary.tomes,
        allowedExtensions: ['pdf'],
      ),
      throwsStateError,
    );
    expect(
      await tempDir.list(recursive: true).where((e) => e is File).toList(),
      isEmpty,
    );
  });

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
