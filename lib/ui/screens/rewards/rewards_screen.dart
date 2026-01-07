import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tela de recompensas: onde o usuário gasta pontos/coins
/// em prêmios personalizados (breaks, compras, mimos, etc).
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rewards',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Troque seus pontos por recompensas da vida real.\n'
            'Você pode cadastrar recompensas como: assistir série, pedir delivery, '
            'comprar algo, tempo de lazer, etc.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _RewardPlaceholderTile(
                  title: 'Adicionar nova recompensa',
                  subtitle:
                      'Ex: 50 pontos → 30min de jogo / 100 pontos → comprar um livro',
                  icon: Icons.add_card_outlined,
                ),
                const SizedBox(height: 8),
                _RewardPlaceholderTile(
                  title: 'Histórico de recompensas',
                  subtitle:
                      'No futuro, veja aqui o que você já “comprou” com seus pontos.',
                  icon: Icons.history,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPlaceholderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _RewardPlaceholderTile({
    required this.title,
    required this.subtitle,
    required this.icon,
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
          Icon(icon, color: AppTheme.accentAmber),
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
                  subtitle,
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


