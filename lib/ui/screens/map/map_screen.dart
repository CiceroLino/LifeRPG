import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tela principal de mapa / visão geral do mundo.
/// Futuramente pode exibir um mapa com regiões, áreas de foco, etc.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'World Map',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualize suas áreas de foco como regiões do mundo.\n'
            'No futuro aqui podem aparecer mapas, zonas (Work, Health, Study...) '
            'e clusters de missões por contexto.',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  color: AppTheme.surface,
                ),
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'Mapa interativo em construção',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


