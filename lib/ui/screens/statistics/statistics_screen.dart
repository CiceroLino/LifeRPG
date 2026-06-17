import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission_completion_event.dart';
import '../../../data/repositories/mission_completion_history_repository.dart';

const int _maxSessionsInLog = 20;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final MissionCompletionHistoryRepository _historyRepository =
      MissionCompletionHistoryRepository();
  late Future<_StatisticsData> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StatisticsData>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? const _StatisticsData();
        final totals = _DailyStats.sum(data.dailyStats);
        final sessions = data.recentSessions;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _statsFuture = _loadStats();
            });
            await _statsFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Last 7 Days',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SummaryTile(
                    icon: Icons.flag_outlined,
                    label: 'Missões',
                    value: totals.completed.toString(),
                  ),
                  _SummaryTile(
                    icon: Icons.stars_outlined,
                    label: 'XP',
                    value: totals.xp.toString(),
                  ),
                  _SummaryTile(
                    icon: Icons.diamond_outlined,
                    label: 'RP',
                    value: totals.rp.toString(),
                  ),
                  _SummaryTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Drops',
                    value: totals.drops.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children:
                      data.dailyStats.map(_DailyStatsRow.new).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sessões',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(14),
                child: sessions.isEmpty
                    ? const Text(
                        'Ainda não há sessões concluídas.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      )
                    : Column(
                        children: List.generate(sessions.length, (index) {
                          return _SessionHistoryRow(
                            sessionIndex: index + 1,
                            event: sessions[index],
                          );
                        }),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_StatisticsData> _loadStats() async {
    final history = await _historyRepository.getAll();
    final recentSessions =
        history.take(_maxSessionsInLog).toList(growable: false);

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final days = List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      return _DailyStats(date: date);
    });

    for (final event in history) {
      final eventDay = DateTime(
        event.completedAt.year,
        event.completedAt.month,
        event.completedAt.day,
      );
      final index = eventDay.difference(start).inDays;
      if (index < 0 || index >= days.length) continue;
      days[index] = days[index].add(event);
    }

    return _StatisticsData(dailyStats: days, recentSessions: recentSessions);
  }
}

class _StatisticsData {
  final List<_DailyStats> dailyStats;
  final List<MissionCompletionEvent> recentSessions;

  const _StatisticsData({
    this.dailyStats = const <_DailyStats>[],
    this.recentSessions = const <MissionCompletionEvent>[],
  });
}

class _DailyStats {
  final DateTime date;
  final int completed;
  final int xp;
  final int rp;
  final int drops;

  const _DailyStats({
    required this.date,
    this.completed = 0,
    this.xp = 0,
    this.rp = 0,
    this.drops = 0,
  });

  _DailyStats add(MissionCompletionEvent event) {
    return _DailyStats(
      date: date,
      completed: completed + 1,
      xp: xp + event.xpGranted,
      rp: rp + event.rewardPointsGranted,
      drops: drops + event.rewardDrops.where((drop) => drop.wasAwarded).length,
    );
  }

  static _DailyStats sum(List<_DailyStats> values) {
    return values.fold(
      _DailyStats(date: DateTime.now()),
      (sum, day) => _DailyStats(
        date: sum.date,
        completed: sum.completed + day.completed,
        xp: sum.xp + day.xp,
        rp: sum.rp + day.rp,
        drops: sum.drops + day.drops,
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
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

class _DailyStatsRow extends StatelessWidget {
  final _DailyStats stats;

  const _DailyStatsRow(this.stats);

  @override
  Widget build(BuildContext context) {
    final label =
        '${stats.date.day.toString().padLeft(2, '0')}/'
        '${stats.date.month.toString().padLeft(2, '0')}';
    final maxScore = [
      stats.completed,
      stats.xp ~/ 10,
      stats.rp,
      stats.drops,
    ].reduce((value, element) => value > element ? value : element);
    final progress = maxScore == 0 ? 0.0 : (maxScore / 10).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.background,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 136,
            child: Text(
              '${stats.completed} M | ${stats.xp} XP | ${stats.rp} RP',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryRow extends StatelessWidget {
  final int sessionIndex;
  final MissionCompletionEvent event;

  const _SessionHistoryRow({
    required this.sessionIndex,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '#$sessionIndex',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.missionTitleSnapshot,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDateTime(event.completedAt)} · XP ${event.xpGranted} | RP ${event.rewardPointsGranted}',
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

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
