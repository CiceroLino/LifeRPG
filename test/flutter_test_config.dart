import 'dart:async';
import 'dart:io';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final directory = await Directory.systemTemp.createTemp('liferpg-test-');
  await File(p.join(directory.path, '.liferpg-test')).writeAsString('isolated');
  await databaseFactory.setDatabasesPath(directory.path);
  tearDownAll(() async {
    await DatabaseHelper().close();
    await directory.delete(recursive: true);
  });
  await testMain();
}
