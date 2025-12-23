import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/skill_provider.dart';
import '../../widgets/skill/skill_linear_item.dart';

class SkillsView extends StatelessWidget {
  const SkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
      ),
      body: Consumer<SkillProvider>(
        builder: (context, provider, _) {
          final skills = provider.skills;
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: AppTheme.primary,
                  tabs: [
                    Tab(text: 'LIST'),
                    Tab(text: 'RADAR'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(skills),
                      _buildRadar(skills),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List skills) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return SkillLinearItem(skill: skill);
      },
    );
  }

  Widget _buildRadar(List skills) {
    if (skills.isEmpty) {
      return const Center(
        child: Text(
          'Sem skills para exibir',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    // Limitar número para visualização
    final radarSkills = skills.take(8).toList();
    final maxValue = (radarSkills.map((s) => s.level).fold<int>(1, (p, e) => e > p ? e : p)).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          gridBorderData: BorderSide(color: AppTheme.border.withOpacity(0.6), width: 1),
          radarBorderData: const BorderSide(color: Colors.transparent),
          tickBorderData: BorderSide(color: AppTheme.border.withOpacity(0.6), width: 1),
          tickCount: 4,
          titlePositionPercentageOffset: 0.15,
          titleTextStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
          dataSets: [
            RadarDataSet(
              fillColor: AppTheme.primary.withOpacity(0.5),
              borderColor: AppTheme.primary,
              entryRadius: 3,
              borderWidth: 2,
              dataEntries: radarSkills
                  .map((s) => RadarEntry(value: s.level.toDouble()))
                  .toList(),
            ),
          ],
          getTitle: (index) {
            if (index < 0 || index >= radarSkills.length) return '';
            return radarSkills[index].name;
          },
          radarShape: RadarShape.polygon,
          radarTouchData: const RadarTouchData(enabled: false),
          tickLabels: const [
            '0',
            '25%',
            '50%',
            '75%',
            '100%',
          ],
          tickLabelTextStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

