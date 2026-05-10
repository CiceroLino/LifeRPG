import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String?> pickAndStoreCustomAvatar() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowedExtensions: ['png', 'jpg', 'jpeg', 'svg', 'gif', 'webp'],
  );

  if (result == null || result.files.single.path == null) {
    return null;
  }

  final filePath = result.files.single.path!;
  final appDir = await getApplicationDocumentsDirectory();
  final customIconsDir = Directory(path.join(appDir.path, 'custom_icons'));
  if (!await customIconsDir.exists()) {
    await customIconsDir.create(recursive: true);
  }

  final fileName = path.basename(filePath);
  final destPath = path.join(customIconsDir.path, fileName);
  final destFile = await File(filePath).copy(destPath);
  return destFile.path;
}
