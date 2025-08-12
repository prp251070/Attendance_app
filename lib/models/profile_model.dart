class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String? createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.createdAt,
  });

  /// Convert from SQLite Map (database row) to ProfileModel
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      email: map['email'],
      role: map['role'],
      createdAt: map['created_at'],
    );
  }

  /// Convert ProfileModel to Map (for inserting into SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'created_at': createdAt,
    };
  }

  /// Convert from Supabase JSON (if needed)
  factory ProfileModel.fromSupabase(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      createdAt: json['created_at'],
    );
  }

  /// Convert to Supabase-compatible map (if needed)
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'created_at': createdAt,
    };
  }
}
