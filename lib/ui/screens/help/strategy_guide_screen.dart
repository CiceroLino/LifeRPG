import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class StrategyGuideScreen extends StatelessWidget {
  const StrategyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Strategy Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _GuideSection(
            title: 'Attributes',
            body:
                'Difficulty measures effort and focus. Urgency measures time '
                'pressure. Fear measures aversion, uncertainty, or anxiety. '
                'LifeRPG groups values as Low 0-25, Medium 26-50, High 51-75, '
                'and Extreme 76-100. Avoid setting Difficulty or Urgency to 0 '
                'unless the mission should award no XP.',
          ),
          _GuideTable(
            title: 'Attribute Landmarks',
            rows: [
              ['10%', 'Trivial', 'Optional', 'Negligible'],
              ['20%', 'Beginner', 'Non-urgent', 'Eustress'],
              ['30%', 'Breeze', 'Free', 'Excitement'],
              ['40%', 'Easy', 'Low', 'Jitters'],
              ['50%', 'Medium', 'Middle', 'Moderate'],
              ['60%', 'Hard', 'High', 'Worry'],
              ['70%', 'Challenge', 'Major', 'Gloom'],
              ['80%', 'Expert', 'Superlative', 'Obsession'],
              ['90%', 'Extreme', 'Immediate', 'Dread'],
              ['100%', 'Transformational', 'Critical', 'Mortal'],
            ],
          ),
          _GuideSection(
            title: 'Skills',
            body:
                'Skills should describe traits or areas of life you want to '
                'improve. Attach one or more skills to each mission. When a '
                'mission is completed, its XP is divided across those skills.',
          ),
          _GuideSection(
            title: 'Parent Missions',
            body:
                'Use parent missions for larger projects. A mission may have '
                'one parent and many children. Child missions use gentler RP '
                'recommendations because they are part of a larger reward path.',
          ),
          _GuideTable(
            title: 'Mission RP Recommendations',
            rows: [
              ['RP', 'Non-child', 'Child'],
              ['1', 'Daily only', 'Daily or weekly'],
              ['5', '0-100 XP', '0-1,000 XP'],
              ['10', '101-1,000 XP', '1,001-10,000 XP'],
              ['25', '1,001-10,000 XP', '10,001-100,000 XP'],
              ['50', '10,001-100,000 XP', '100,001-1,000,000 XP'],
              ['75', '100,001-1,000,000 XP', '1,000,001+ XP'],
              ['100', '1,000,001+ XP', 'Not recommended'],
            ],
          ),
          _GuideSection(
            title: 'Rewards',
            body:
                'For real-world rewards, a practical price is '
                'modified cost divided by stock. Round the real-world cost up '
                'to a useful currency step, multiply by 0.5, 1, or 2 depending '
                'on how useful or distracting the reward is, then divide by the '
                'number of reward units in stock.',
          ),
          _GuideSection(
            title: 'Energy',
            body:
                'Energy represents daily capacity. Manual mode lets you set it '
                'directly. Automatic mode follows your wake and sleep schedule. '
                'Use it to decide how much work to take on today.',
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final String body;

  const _GuideSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideTitle(title),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _GuideTable extends StatelessWidget {
  final String title;
  final List<List<String>> rows;

  const _GuideTable({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideTitle(title),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            border: TableBorder.symmetric(
              inside: const BorderSide(color: AppTheme.border),
            ),
            children: rows
                .map(
                  (row) => TableRow(
                    children: row
                        .map(
                          (cell) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Text(
                              cell,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final Widget child;

  const _GuideCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _GuideTitle extends StatelessWidget {
  final String title;

  const _GuideTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}
