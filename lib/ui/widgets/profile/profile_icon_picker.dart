import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

/// Lista de ícones SVG específicos para perfil (apenas ícones que existem no projeto)
const List<String> _profileSvgIcons = [
  // Perfil / Personagem
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/hooded-figure.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/hooded-assassin.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/ninja-head.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/person.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/character.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/black-knight-helm.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/knight-banner.svg',
  // Asas / Aura
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/angel-wings.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/aura.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/feathered-wing.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/angel-outfit.svg',
  // Classes / Profissões
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/delapouite/skills.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/darkzaitzev/apothecary.svg',
  // Elementos / Objetos
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/brain.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/edged-shield.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/fireball.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/compass.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/light-bulb.svg',
  'assets/game-icons.net.svg/icons/ffffff/transparent/1x1/lorc/bookmark.svg',
];

/// Mostra um dialog/bottom sheet para selecionar um ícone de perfil
/// Retorna o caminho do SVG selecionado ou null se cancelado
Future<String?> showProfileIconPicker(
  BuildContext context, {
  String? currentIconPath,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _ProfileIconPickerContent(currentIconPath: currentIconPath),
      );
    },
  );
}

class _ProfileIconPickerContent extends StatefulWidget {
  final String? currentIconPath;

  const _ProfileIconPickerContent({this.currentIconPath});

  @override
  State<_ProfileIconPickerContent> createState() =>
      _ProfileIconPickerContentState();
}

class _ProfileIconPickerContentState extends State<_ProfileIconPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  List<String> get _filteredSvgIcons {
    if (_query.isEmpty) return _profileSvgIcons;
    return _profileSvgIcons.where((path) {
      final fileName = path
          .split('/')
          .last
          .replaceAll('.svg', '')
          .replaceAll('-', ' ');
      return fileName.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com busca
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select Profile Icon',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  hintText: 'Search icons...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grid de ícones SVG
        Expanded(
          child: _filteredSvgIcons.isEmpty
              ? const Center(
                  child: Text(
                    'No icons found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _filteredSvgIcons.length,
                  itemBuilder: (context, index) {
                    final iconPath = _filteredSvgIcons[index];
                    final isSelected = iconPath == widget.currentIconPath;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, iconPath),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          iconPath,
                          colorFilter: const ColorFilter.mode(
                            AppTheme.textPrimary,
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (_) => const SizedBox(
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          errorBuilder: (_, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
