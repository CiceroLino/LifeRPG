class Note {
  final int? id;
  final int notebookId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    this.id,
    required this.notebookId,
    required this.title,
    this.body = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebook_id': notebookId,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      notebookId: map['notebook_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Note copyWith({
    int? id,
    int? notebookId,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
