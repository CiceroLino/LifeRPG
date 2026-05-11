class FocusSession {
  final int? id;
  final int plannedMinutes;
  final int completedMinutes;
  final int xpGranted;
  final String status;
  final DateTime startedAt;
  final DateTime completedAt;

  const FocusSession({
    this.id,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.xpGranted,
    required this.status,
    required this.startedAt,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'planned_minutes': plannedMinutes,
      'completed_minutes': completedMinutes,
      'xp_granted': xpGranted,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as int?,
      plannedMinutes: map['planned_minutes'] as int? ?? 0,
      completedMinutes: map['completed_minutes'] as int? ?? 0,
      xpGranted: map['xp_granted'] as int? ?? 0,
      status: map['status'] as String? ?? 'completed',
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}
