import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/core/platform/desktop_database_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../support/test_database.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('storage-test-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<void> seed(String path, String name) async {
    await Directory(p.dirname(path)).create(recursive: true);
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('CREATE TABLE sentinel (name TEXT)');
    await db.insert('sentinel', {'name': name});
    await db.close();
  }

  Future<String> nameAt(String path) async {
    final db = await databaseFactoryFfi.openDatabase(path);
    final rows = await db.query('sentinel');
    await db.close();
    return rows.single['name'] as String;
  }

  test('legacy snapshot migrates without deleting the original', () async {
    final legacy = p.join(root.path, 'old', 'liferpg.db');
    final support = p.join(root.path, 'support');
    await seed(legacy, 'progress');
    final directory = await prepareDesktopDatabaseDirectory(
      supportPath: support,
      legacyPath: legacy,
    );
    expect(await nameAt(p.join(directory, 'liferpg.db')), 'progress');
    expect(await nameAt(legacy), 'progress');
    expect(directory, p.join(support, 'databases'));
    await Directory(p.dirname(legacy)).delete(recursive: true);
    expect(await nameAt(p.join(directory, 'liferpg.db')), 'progress');
  });

  test(
    'an existing destination is never replaced by a legacy database',
    () async {
      final legacy = p.join(root.path, 'old', 'liferpg.db');
      final support = p.join(root.path, 'support');
      await seed(legacy, 'old');
      await seed(p.join(support, 'databases', 'liferpg.db'), 'current');
      final directory = await prepareDesktopDatabaseDirectory(
        supportPath: support,
        legacyPath: legacy,
      );
      expect(await nameAt(p.join(directory, 'liferpg.db')), 'current');
      expect(await nameAt(legacy), 'old');
    },
  );

  test(
    'database identity depends on support directory rather than cwd',
    () async {
      final support = p.join(root.path, 'support');
      final first = await prepareDesktopDatabaseDirectory(
        supportPath: support,
        legacyPath: p.join(root.path, 'cwd-a', 'liferpg.db'),
      );
      await seed(p.join(first, 'liferpg.db'), 'stable');
      final second = await prepareDesktopDatabaseDirectory(
        supportPath: support,
        legacyPath: p.join(root.path, 'cwd-b', 'liferpg.db'),
      );
      expect(second, first);
      expect(await nameAt(p.join(second, 'liferpg.db')), 'stable');
    },
  );

  test(
    'test reset refuses unmarked databases and preserves their bytes',
    () async {
      final original = await getDatabasesPath();
      final outside = p.join(root.path, 'unmarked');
      final sentinel = p.join(outside, 'liferpg.db');
      await seed(sentinel, 'do not erase');
      final before = await File(sentinel).readAsBytes();
      try {
        await databaseFactory.setDatabasesPath(outside);
        await expectLater(resetTestDatabase(), throwsStateError);
        expect(await File(sentinel).readAsBytes(), before);
      } finally {
        await databaseFactory.setDatabasesPath(original);
      }
    },
  );
}
