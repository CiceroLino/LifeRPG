import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'desktop_database_storage.dart';

Future<void> configureDatabasePlatform() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final legacyPath = p.join(await getDatabasesPath(), 'liferpg.db');
    final support = await getApplicationSupportDirectory();
    final directory = await prepareDesktopDatabaseDirectory(
      supportPath: support.path,
      legacyPath: legacyPath,
    );
    await databaseFactory.setDatabasesPath(directory);
  }
}
