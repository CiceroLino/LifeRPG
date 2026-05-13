import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/tome.dart';
import 'package:liferpg/providers/tome_provider.dart';
import 'package:liferpg/services/local_media_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TomeProvider provider;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('liferpg_tome_provider_');
    provider = TomeProvider(
      mediaImporter: createLocalMediaImportService(basePath: tempDir.path),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loads tomes and filters by search query', () async {
    await provider.addTome(
      Tome(title: 'Flutter Tome', author: 'Mage', filePath: '/tmp/flutter.pdf'),
    );
    await provider.addTome(
      Tome(title: 'Cooking Notes', author: 'Chef', filePath: '/tmp/cook.pdf'),
    );

    provider.setSearchQuery('mage');

    expect(provider.filteredTomes, hasLength(1));
    expect(provider.filteredTomes.single.title, 'Flutter Tome');
  });

  test('updates and archives tomes', () async {
    final id = await provider.addTome(
      Tome(title: 'Draft Tome', filePath: '/tmp/draft.pdf'),
    );

    await provider.updateTome(
      provider.tomes.single.copyWith(currentPage: 3, totalPages: 10),
    );
    expect(provider.tomes.single.progress, 0.3);

    await provider.archiveTome(id!);
    expect(provider.tomes, isEmpty);
  });

  test('updates reading progress from embedded reader', () async {
    final id = await provider.addTome(
      Tome(title: 'Reader Tome', filePath: '/tmp/reader.pdf'),
    );

    await provider.updateReadingProgress(id!, currentPage: 4, totalPages: 20);

    expect(provider.tomes.single.currentPage, 4);
    expect(provider.tomes.single.totalPages, 20);
    expect(provider.tomes.single.progress, 0.2);
  });

  test('imports picked PDF into managed storage before saving tome', () async {
    final id = await provider.importTome(
      PlatformFile(
        name: 'Dungeon Manual.pdf',
        size: 3,
        readStream: Stream.value([1, 2, 3]),
      ),
    );

    expect(id, isNotNull);
    expect(provider.tomes.single.title, 'Dungeon Manual');
    expect(provider.tomes.single.filePath, contains('tomes'));
    expect(await File(provider.tomes.single.filePath).readAsBytes(), [1, 2, 3]);
  });
}
