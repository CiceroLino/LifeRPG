import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tela de inventário: itens, consumíveis, equipamentos simbólicos.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veja seus “itens” de RPG aplicados à vida real.\n'
            'Podem ser itens simbólicos (poção de foco, elmo da disciplina) '
            'ou recursos que você quer acompanhar.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _InventorySlotPlaceholder(label: 'Adicionar item'),
                _InventorySlotPlaceholder(label: 'Itens consumíveis'),
                _InventorySlotPlaceholder(label: 'Equipamentos'),
                _InventorySlotPlaceholder(label: 'Colecionáveis'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventorySlotPlaceholder extends StatelessWidget {
  final String label;

  const _InventorySlotPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        color: AppTheme.surface,
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}


