import 'package:flutter/material.dart';

Widget buildAvatarImage(
  String avatarPath, {
  required Widget Function() placeholderBuilder,
  BoxFit fit = BoxFit.cover,
}) {
  return placeholderBuilder();
}
