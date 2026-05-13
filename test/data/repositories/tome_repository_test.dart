import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/tome.dart';
import 'package:liferpg/data/repositories/tome_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TomeRepository tomes;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    tomes = TomeRepository();
  });

  test('creates, updates, lists, opens, and archives tomes', () async {
    final id = await tomes.insertTome(
      Tome(
        title: 'The First Tome',
        author: 'Archivist',
        filePath: '/tmp/a.pdf',
      ),
    );

    var stored = await tomes.getTomeById(id);
    expect(stored!.title, 'The First Tome');
    expect(stored.author, 'Archivist');
    expect(stored.progress, 0);

    await tomes.updateTome(
      stored.copyWith(
        title: 'The Second Tome',
        currentPage: 20,
        totalPages: 100,
      ),
    );

    stored = await tomes.getTomeById(id);
    expect(stored!.title, 'The Second Tome');
    expect(stored.progress, 0.2);

    await tomes.markOpened(id);
    stored = await tomes.getTomeById(id);
    expect(stored!.lastOpenedAt, isNotNull);

    expect(await tomes.getActiveTomes(), hasLength(1));
    await tomes.archiveTome(id);
    expect(await tomes.getActiveTomes(), isEmpty);
    expect((await tomes.getTomeById(id))!.isActive, isFalse);
  });

  test('backup and restore preserve tomes', () async {
    await tomes.insertTome(
      Tome(
        title: 'Restore Tome',
        description: 'Portable PDF reference',
        filePath: '/tmp/restore.pdf',
        currentPage: 12,
        totalPages: 120,
      ),
    );

    final backup = await DatabaseHelper().getAllDataForBackup();
    expect(backup['tomes'], hasLength(1));

    await DatabaseHelper().restoreData(backup);

    final restored = await tomes.getActiveTomes();
    expect(restored.single.title, 'Restore Tome');
    expect(restored.single.currentPage, 12);
  });
}
