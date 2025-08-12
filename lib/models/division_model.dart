class DivisionModel {
  final String id;
  final String name;
  final String? createdAt;

  DivisionModel({
    required this.id,
    required this.name,
    this.createdAt,
  });
  DivisionModel copyWith({
    String? id,
    String? name,
    String? createdAt,
  }) {
    return DivisionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert from SQLite Map (database row) to DivisionModel
  factory DivisionModel.fromMap(Map<String, dynamic> map) {
    return DivisionModel(
      id: map['id'],
      name: map['name'],
      createdAt: map['created_at'],
    );
  }

  /// Convert DivisionModel to Map (for inserting into SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  /// Convert from Supabase JSON (if needed)
  factory DivisionModel.fromSupabase(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
    );
  }

  /// Convert to Supabase-compatible map (if needed)
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }
}
