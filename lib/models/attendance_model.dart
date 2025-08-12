class AttendanceModel {
  final String id;
  final String studentId;
  final String divisionId;
  final String date; // Format: YYYY-MM-DD
  final bool isPresent;
  final String? reason;
  final bool isSync;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.divisionId,
    required this.date,
    required this.isPresent,
    this.reason,
    this.isSync = false,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      studentId: map['student_id'],
      divisionId: map['division_id'],
      date: map['date'],
      isPresent: map['is_present'] == 1,
      reason: map['reason'],
      isSync: map['is_sync'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'division_id': divisionId,
      'date': date,
      'is_present': isPresent ? 1 : 0,
      'reason': reason,
      'is_sync': isSync ? 1 : 0,
    };
  }
}
