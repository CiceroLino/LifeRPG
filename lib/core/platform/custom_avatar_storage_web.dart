import 'dart:convert';

import 'package:file_picker/file_picker.dart';

Future<String?> pickAndStoreCustomAvatar() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowedExtensions: ['png', 'jpg', 'jpeg', 'svg', 'gif', 'webp'],
    withData: true,
  );

  if (result == null || result.files.single.bytes == null) {
    return null;
  }

  final file = result.files.single;
  final mimeType = _mimeTypeForExtension(file.extension);
  return 'data:$mimeType;base64,${base64Encode(file.bytes!)}';
}

String _mimeTypeForExtension(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'svg':
      return 'image/svg+xml';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'png':
    default:
      return 'image/png';
  }
}
