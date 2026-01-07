import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/skill_provider.dart';
import '../../widgets/skill/skill_linear_item.dart';

class SkillsView extends StatelessWidget {
  const SkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: const TabBar(
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              tabs: [
                Tab(text: 'ALL'),
                Tab(text: 'TOP'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SkillProvider>(
              builder: (context, skillProvider, _) {
                final skills = skillProvider.skills;

                if (skillProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  children: [
                    _buildAllList(skills),
                    _buildTopChart(skills),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllList(List skills) {
    if (skills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 64,
              color: AppTheme.textPrimary,
            ),
            SizedBox(height: 16),
            Text(
              'No skills yet',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return SkillLinearItem(skill: skill);
      },
    );
  }

  Widget _buildTopChart(List skills) {
    if (skills.length < 3) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 64,
              color: AppTheme.textPrimary,
            ),
            SizedBox(height: 16),
            Text(
              'You need at least 3 skills to view chart.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'Chart view (coming soon)',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}

