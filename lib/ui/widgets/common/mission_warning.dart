import 'package:flutter/material.dart';

void showMissionWarning(BuildContext context, String? warning) {
  if (warning == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(warning)));
}
