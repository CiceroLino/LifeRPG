import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/skill.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/skill_provider.dart';
import '../../widgets/skill/skill_linear_item.dart';

class SkillsView extends StatefulWidget {
  const SkillsView({super.key});

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Skill> _filteredSkills(List<Skill> skills, AppLocalizations l10n) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return skills;

    return skills
        .where(
          (skill) =>
              skill.name.toLowerCase().contains(query) ||
              (skill.description.toLowerCase().contains(query)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: TabBar(
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              tabs: [
                Tab(text: l10n.translate('all')),
                Tab(text: l10n.translate('chart')),
              ],
            ),
          ),
          _SkillsSearchField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          Expanded(
            child: Consumer<SkillProvider>(
              builder: (context, skillProvider, _) {
                final skills = _filteredSkills(skillProvider.skills, l10n);
                if (skillProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  children: [
                    _buildAllList(skillProvider.skills, skills, l10n),
                    _buildTopChart(skills, l10n),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllList(
    List<Skill> sourceSkills,
    List<Skill> skills,
    AppLocalizations l10n,
  ) {
    if (sourceSkills.isEmpty) {
      return _EmptyState(message: l10n.translate('no_skills_yet'));
    }

    if (skills.isEmpty) {
      return _EmptyState(message: l10n.translate('no_skills_found'));
    }

    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return SkillLinearItem(skill: skill);
      },
    );
  }

  Widget _buildTopChart(List<Skill> skills, AppLocalizations l10n) {
    if (skills.length < 3) {
      return _EmptyState(message: l10n.translate('chart_unavailable'));
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(
                height: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SkillSpiderChart(
                    skills: skills,
                    axisCenterLabel: l10n.translate('skill_graph_axis_level'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillsSearchField extends StatelessWidget {
  const _SkillsSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppTheme.surface,
          hintText: l10n.translate('search_skills'),
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
            onPressed: onClear,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SkillSpiderChart extends StatelessWidget {
  const SkillSpiderChart({
    super.key,
    required this.skills,
    this.axisCenterLabel = 'Skills',
  });

  final List<Skill> skills;
  final String axisCenterLabel;

  double _maxProgress() {
    final values = skills.map((skill) {
      final total = ((skill.level - 1) * 100 + skill.currentXP).toDouble();
      return total > 0 ? total : 0.0;
    }).toList();

    final maxValue = values.isEmpty ? 1.0 : values.reduce(math.max);
    return maxValue <= 0 ? 1.0 : maxValue;
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = _maxProgress();
    return CustomPaint(
      painter: _SkillSpiderPainter(
        skills: skills,
        maxValue: maxValue,
        axisCenterLabel: axisCenterLabel,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SkillSpiderPainter extends CustomPainter {
  const _SkillSpiderPainter({
    required this.skills,
    required this.maxValue,
    required this.axisCenterLabel,
  });

  final List<Skill> skills;
  final double maxValue;
  final String axisCenterLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (skills.isEmpty || size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 46;
    if (radius <= 0) return;

    final axisPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final bgPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;

    for (var ring = 1; ring <= 5; ring++) {
      final ringRadius = radius * (ring / 5);
      final path = Path();
      final stepAngle = (math.pi * 2) / skills.length;

      for (var i = 0; i < skills.length; i++) {
        final angle = i * stepAngle - (math.pi / 2);
        final point = Offset(
          center.dx + ringRadius * math.cos(angle),
          center.dy + ringRadius * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = AppTheme.surface.withValues(alpha: 0.12),
      );
      canvas.drawPath(path, axisPaint);
    }

    final skillMax = maxValue <= 0 ? 1.0 : maxValue;
    final areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primary.withValues(alpha: 0.18);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.primary;

    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    );

    final stepAngle = (math.pi * 2) / skills.length;
    final path = Path();

    for (var i = 0; i < skills.length; i++) {
      final skill = skills[i];
      final value =
          (((skill.level - 1) * 100 + skill.currentXP).toDouble() / skillMax)
              .clamp(0.05, 1.0);
      final angle = i * stepAngle - (math.pi / 2);
      final r = radius * value;

      final axisEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final valuePoint = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(valuePoint.dx, valuePoint.dy);
      } else {
        path.lineTo(valuePoint.dx, valuePoint.dy);
      }

      canvas.drawLine(center, axisEnd, bgPaint..strokeWidth = 1);

      labelPaint.text = TextSpan(
        text: skill.name,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11),
      );
      labelPaint.layout(maxWidth: 72);
      final labelOffset = Offset(
        center.dx + (radius + 24) * math.cos(angle) - labelPaint.width / 2,
        center.dy + (radius + 24) * math.sin(angle) - labelPaint.height / 2,
      );
      labelPaint.paint(canvas, labelOffset);

      final radiusPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _parseColor(skill.color);
      canvas.drawCircle(valuePoint, 4.5, radiusPaint);
    }

    path.close();
    canvas.drawPath(path, areaPaint);
    canvas.drawPath(path, borderPaint);

    final centerText = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: axisCenterLabel,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    centerText.layout();
    centerText.paint(
      canvas,
      Offset(
        center.dx - centerText.width / 2,
        center.dy - centerText.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SkillSpiderPainter oldDelegate) {
    return oldDelegate.skills != skills || oldDelegate.maxValue != maxValue;
  }
}

Color _parseColor(String hexColor) {
  final color = hexColor.replaceAll('#', '').trim();
  if (color.length != 6) return AppTheme.primary;
  return Color(int.parse('FF$color', radix: 16)).withValues(alpha: 1);
}
