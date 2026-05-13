class Tome {
  final int? id;
  final String title;
  final String author;
  final String description;
  final String filePath;
  final int currentPage;
  final int? totalPages;
  final bool isActive;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tome({
    this.id,
    required this.title,
    this.author = '',
    this.description = '',
    required this.filePath,
    this.currentPage = 0,
    this.totalPages,
    this.isActive = true,
    this.lastOpenedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get progress {
    final total = totalPages;
    if (total == null || total <= 0 || currentPage <= 0) return 0;
    return (currentPage / total).clamp(0, 1);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'file_path': filePath,
      'current_page': currentPage,
      'total_pages': totalPages,
      'is_active': isActive ? 1 : 0,
      'last_opened_at': lastOpenedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Tome.fromMap(Map<String, dynamic> map) {
    return Tome(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String? ?? '',
      description: map['description'] as String? ?? '',
      filePath: map['file_path'] as String,
      currentPage: map['current_page'] as int? ?? 0,
      totalPages: map['total_pages'] as int?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      lastOpenedAt: map['last_opened_at'] == null
          ? null
          : DateTime.parse(map['last_opened_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Tome copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? filePath,
    int? currentPage,
    int? totalPages,
    bool clearTotalPages = false,
    bool? isActive,
    DateTime? lastOpenedAt,
    bool clearLastOpenedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tome(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      currentPage: currentPage ?? this.currentPage,
      totalPages: clearTotalPages ? null : totalPages ?? this.totalPages,
      isActive: isActive ?? this.isActive,
      lastOpenedAt: clearLastOpenedAt
          ? null
          : lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
