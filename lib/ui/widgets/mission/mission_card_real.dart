import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/mission.dart';
import '../../../core/theme/app_theme.dart';

class MissionCardReal extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const MissionCardReal({
    super.key,
    required this.mission,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.bullseye,
                      color: AppTheme.primaryPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (mission.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            mission.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle_outline),
                    color: AppTheme.successGreen,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _AttributeChip(
                    icon: Icons.fitness_center,
                    label: 'Dif ${mission.difficulty}',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _AttributeChip(
                    icon: Icons.warning_amber,
                    label: 'Urg ${mission.urgency}',
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _AttributeChip(
                    icon: Icons.stars,
                    label: '${mission.xpReward} XP',
                    color: AppTheme.xpBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttributeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AttributeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}