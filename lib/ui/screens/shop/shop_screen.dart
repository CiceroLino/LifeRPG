import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tela de loja: cosméticos, pacotes de ícones, temas, etc.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aqui você pode imaginar uma loja de cosméticos do app: '
            'temas, pacotes de ícones, skins, etc.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _ShopItemPlaceholder(
                  title: 'Tema Neon',
                  description: 'Tema visual alternativo para o aplicativo.',
                ),
                SizedBox(height: 8),
                _ShopItemPlaceholder(
                  title: 'Pacote de Ícones “Sci‑Fi”',
                  description: 'Conjunto de ícones especiais para missões e menus.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemPlaceholder extends StatelessWidget {
  final String title;
  final String description;

  const _ShopItemPlaceholder({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.primary.withOpacity(0.18),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


