import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';

class MissionListItem extends StatelessWidget {
  final Mission mission;
  final Color priorityColor;
  final VoidCallback? onTap;
  final VoidCallback? onAddSubtask;

  const MissionListItem({
    super.key,
    required this.mission,
    required this.priorityColor,
    this.onTap,
    this.onAddSubtask,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 56,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.bullseye,
                  color: AppTheme.textPrimary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (mission.description.isNotEmpty)
                    Text(
                      mission.description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  color: AppTheme.textSecondary,
                  onPressed: onTap,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.expand_more, size: 18),
                  color: AppTheme.textSecondary,
                  onPressed: onTap,
                ),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.add, size: 18),
              color: AppTheme.primary,
              onPressed: onAddSubtask,
            ),
          ],
        ),
      ),
    );
  }
}
