import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';

Future<IconData?> showIconPickerDialog(
  BuildContext context, {
  IconData? initialIcon,
}) {
  return showDialog<IconData>(
    context: context,
    builder: (context) => const IconPickerDialog(),
  );
}

class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({super.key});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static final Map<String, IconData> _iconMap = {
    'task': Icons.check_circle_outline,
    'flag': Icons.flag_outlined,
    'star': Icons.star_border,
    'book': FontAwesomeIcons.book,
    'brain': FontAwesomeIcons.brain,
    'bolt': FontAwesomeIcons.bolt,
    'dumbbell': FontAwesomeIcons.dumbbell,
    'running': FontAwesomeIcons.personRunning,
    'mountain': FontAwesomeIcons.mountain,
    'medkit': FontAwesomeIcons.kitMedical,
    'coins': FontAwesomeIcons.coins,
    'trophy': FontAwesomeIcons.trophy,
    'shopping-cart': FontAwesomeIcons.cartShopping,
    'clock': Icons.access_time,
    'calendar': Icons.calendar_today,
    'shield': FontAwesomeIcons.shieldHalved,
    'fire': FontAwesomeIcons.fire,
    'heart': Icons.favorite_border,
    'music': Icons.music_note,
    'code': FontAwesomeIcons.code,
    'gamepad': FontAwesomeIcons.gamepad,
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _iconMap.entries.where((e) {
      if (_query.isEmpty) return true;
      return e.key.toLowerCase().contains(_query);
    }).toList();

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Icon',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Filter icons',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        height: 320,
        child: GridView.builder(
          padding: const EdgeInsets.only(top: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final entry = filtered[index];
            final icon = entry.value;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context, icon),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(child: Icon(icon, color: Colors.white, size: 22)),
              ),
            );
          },
        ),
      ),
    );
  }
}
