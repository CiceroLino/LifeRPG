import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> configureDatabasePlatform() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
