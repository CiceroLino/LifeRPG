import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

Widget buildAvatarImage(
  String avatarPath, {
  required Widget Function() placeholderBuilder,
  BoxFit fit = BoxFit.cover,
}) {
  if (_isDataUri(avatarPath)) {
    return _buildDataUriAvatar(avatarPath, fit, placeholderBuilder);
  }

  if (_isLocalFilePath(avatarPath)) {
    return placeholderBuilder();
  }

  if (avatarPath.toLowerCase().endsWith('.svg')) {
    return SvgPicture.asset(
      avatarPath,
      fit: fit,
      placeholderBuilder: (_) => placeholderBuilder(),
      errorBuilder: (_, error, stackTrace) => placeholderBuilder(),
    );
  }

  return Image.asset(
    avatarPath,
    fit: fit,
    errorBuilder: (_, error, stackTrace) => placeholderBuilder(),
  );
}

bool _isLocalFilePath(String avatarPath) {
  return avatarPath.startsWith('/') || avatarPath.startsWith('file://');
}

bool _isDataUri(String avatarPath) => avatarPath.startsWith('data:image/');

Widget _buildDataUriAvatar(
  String avatarPath,
  BoxFit fit,
  Widget Function() placeholderBuilder,
) {
  try {
    final commaIndex = avatarPath.indexOf(',');
    if (commaIndex == -1) return placeholderBuilder();

    final metadata = avatarPath.substring(0, commaIndex);
    final bytes = base64Decode(avatarPath.substring(commaIndex + 1));
    if (metadata.contains('image/svg+xml')) {
      return SvgPicture.memory(
        bytes,
        fit: fit,
        colorFilter: const ColorFilter.mode(
          AppTheme.textPrimary,
          BlendMode.srcIn,
        ),
        placeholderBuilder: (_) => placeholderBuilder(),
      );
    }

    return Image.memory(
      bytes,
      fit: fit,
      errorBuilder: (_, error, stackTrace) => placeholderBuilder(),
    );
  } catch (_) {
    return placeholderBuilder();
  }
}
