import '../services/student_local_service.dart';
import '../models/student_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class StudentService {
  final _supabase = Supabase.instance.client;
  final _table = 'students';

  // GET all students by division from Supabase and store locally
  Future<List<StudentModel>> getStudentsByDivision(String divisionId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('division_id', divisionId);

    final List<StudentModel> students = (response as List)
        .map((e) => StudentModel.fromMap(e))
        .toList();

    // Sync to local DB
    await StudentLocalService().insertStudentsBulk(students);

    return students;
  }

  // ADD student to Supabase and SQLite
  Future<void> addStudent(StudentModel student) async {
    await _supabase.from(_table).insert(student.toMap());
    await StudentLocalService().upsertStudent(student);
  }

  // UPDATE student
  Future<void> updateStudent(StudentModel student) async {
    await _supabase
        .from(_table)
        .update(student.toMap())
        .eq('id', student.id);

    await StudentLocalService().upsertStudent(student);
  }

  // DELETE student
  Future<void> deleteStudent(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
    await StudentLocalService().deleteStudent(id);
  }
}
