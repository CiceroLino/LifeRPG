class AudioTrack {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final int? durationMs;
  final int positionMs;
  final bool isActive;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioTrack({
    this.id,
    required this.title,
    this.artist = '',
    this.album = '',
    required this.filePath,
    this.durationMs,
    this.positionMs = 0,
    this.isActive = true,
    this.lastPlayedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Duration? get duration {
    final duration = durationMs;
    if (duration == null) return null;
    return Duration(milliseconds: duration);
  }

  Duration get position => Duration(milliseconds: positionMs);

  double get progress {
    final duration = durationMs;
    if (duration == null || duration <= 0 || positionMs <= 0) return 0;
    return (positionMs / duration).clamp(0, 1);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'file_path': filePath,
      'duration_ms': durationMs,
      'position_ms': positionMs,
      'is_active': isActive ? 1 : 0,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AudioTrack.fromMap(Map<String, dynamic> map) {
    return AudioTrack(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? '',
      album: map['album'] as String? ?? '',
      filePath: map['file_path'] as String,
      durationMs: map['duration_ms'] as int?,
      positionMs: map['position_ms'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      lastPlayedAt: map['last_played_at'] == null
          ? null
          : DateTime.parse(map['last_played_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  AudioTrack copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    int? durationMs,
    bool clearDuration = false,
    int? positionMs,
    bool? isActive,
    DateTime? lastPlayedAt,
    bool clearLastPlayedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      durationMs: clearDuration ? null : durationMs ?? this.durationMs,
      positionMs: positionMs ?? this.positionMs,
      isActive: isActive ?? this.isActive,
      lastPlayedAt: clearLastPlayedAt
          ? null
          : lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
