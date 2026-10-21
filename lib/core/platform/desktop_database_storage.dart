import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Copies a consistent legacy snapshot while retaining both existing databases.
Future<String> prepareDesktopDatabaseDirectory({
  required String supportPath,
  required String legacyPath,
}) async {
  final directory = Directory(p.join(supportPath, 'databases'));
  await directory.create(recursive: true);
  final destination = File(p.join(directory.path, 'liferpg.db'));
  final lock = await File(
    p.join(directory.path, '.migration.lock'),
  ).open(mode: FileMode.append);
  await lock.lock(FileLock.exclusive);
  try {
    if (await destination.exists() || !await File(legacyPath).exists()) {
      return directory.path;
    }
    final temporary = File(
      '${destination.path}.${const Uuid().v4()}.migration',
    );
    try {
      final source = await databaseFactoryFfi.openDatabase(
        legacyPath,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        await source.execute('VACUUM INTO ?', [temporary.path]);
      } finally {
        await source.close();
      }
      final snapshot = await databaseFactoryFfi.openDatabase(
        temporary.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        final check = await snapshot.rawQuery('PRAGMA quick_check');
        if (check.length != 1 || check.single.values.single != 'ok') {
          throw StateError('The legacy database snapshot failed validation.');
        }
      } finally {
        await snapshot.close();
      }
      if (!await destination.exists()) await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    return directory.path;
  } finally {
    await lock.unlock();
    await lock.close();
  }
}
