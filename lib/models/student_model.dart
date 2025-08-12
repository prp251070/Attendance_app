class StudentModel {
  final String id;
  final String name;
  final int rollNumber;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? address;
  final String? contact;
  final String? parentContact;
  final String? email;
  final String? photoUrl;
  final String divisionId;
  final String? createdAt;
  final String? photoLocalPath;
  String? reason;

  StudentModel({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.dateOfBirth,
    this.bloodGroup,
    this.address,
    this.contact,
    this.parentContact,
    this.email,
    this.photoUrl,
    required this.divisionId,
    this.createdAt,
    this.photoLocalPath,
    this.reason,
  });

  /// Convert from SQLite row (Map) to StudentModel
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      name: map['name'],
      rollNumber: map['roll_number'],
      dateOfBirth: map['date_of_birth'],
      bloodGroup: map['blood_group'],
      address: map['address'],
      contact: map['contact'],
      parentContact: map['parent_contact'],
      email: map['email'],
      photoUrl: map['photo_url'],
      divisionId: map['division_id'],
      createdAt: map['created_at'],
      photoLocalPath: map['photo_local_path'],
    );
  }

  /// Convert StudentModel to Map (for inserting into SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'roll_number': rollNumber,
      'date_of_birth': dateOfBirth,
      'blood_group': bloodGroup,
      'address': address,
      'contact': contact,
      'parent_contact': parentContact,
      'email': email,
      'photo_url': photoUrl,
      'division_id': divisionId,
      'created_at': createdAt,
      'photo_local_path': photoLocalPath,
    };
  }

  /// Convert from Supabase JSON to StudentModel
  factory StudentModel.fromSupabase(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      rollNumber: json['roll_number'],
      dateOfBirth: json['date_of_birth'],
      bloodGroup: json['blood_group'],
      address: json['address'],
      contact: json['contact'],
      parentContact: json['parent_contact'],
      email: json['email'],
      photoUrl: json['photo_url'],
      divisionId: json['division_id'],
      createdAt: json['created_at'],
    );
  }

  /// Convert to Supabase-compatible map
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'roll_number': rollNumber,
      'date_of_birth': dateOfBirth,
      'blood_group': bloodGroup,
      'address': address,
      'contact': contact,
      'parent_contact': parentContact,
      'email': email,
      'photo_url': photoUrl,
      'division_id': divisionId,
      'created_at': createdAt,
    };
  }
}
