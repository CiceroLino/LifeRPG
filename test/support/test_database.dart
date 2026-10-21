import 'dart:io';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> resetTestDatabase() async {
  await clearTestDatabase();
  await DatabaseHelper().database;
}

Future<void> clearTestDatabase() async {
  final directory = await getDatabasesPath();
  if (!await File(p.join(directory, '.liferpg-test')).exists()) {
    throw StateError('Refusing to reset a database outside the test sandbox.');
  }
  await DatabaseHelper().close();
  await deleteDatabase(p.join(directory, 'liferpg.db'));
}
