import 'package:sqflite/sqflite.dart';
import '../models/student_model.dart';
import 'local_db_helper.dart';

class StudentLocalService {
  static final StudentLocalService _instance = StudentLocalService._internal();
  factory StudentLocalService() => _instance;
  StudentLocalService._internal();

  // INSERT or UPDATE student (upsert)
  Future<void> upsertStudent(StudentModel student) async {
    final db = await LocalDBHelper().database;
    await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // handles insert or update
    );
  }

  // INSERT multiple students (e.g., from Excel import)
  Future<void> insertStudentsBulk(List<StudentModel> students) async {
    final db = await LocalDBHelper().database;
    final batch = db.batch();

    for (var student in students) {
      batch.insert(
        'students',
        student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // FETCH all students of a particular division
  Future<List<StudentModel>> getStudentsByDivision(String divisionId) async {
    final db = await LocalDBHelper().database;
    final result = await db.query(
      'students',
      where: 'division_id = ?',
      whereArgs: [divisionId],
    );

    return result.map((row) => StudentModel.fromMap(row)).toList();
  }

  // FETCH single student by ID
  Future<StudentModel?> getStudentById(String id) async {
    final db = await LocalDBHelper().database;
    final result = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return StudentModel.fromMap(result.first);
    }
    return null;
  }

  // DELETE a student
  Future<void> deleteStudent(String id) async {
    final db = await LocalDBHelper().database;
    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CLEAR all students (optional utility)
  Future<void> clearAllStudents() async {
    final db = await LocalDBHelper().database;
    await db.delete('students');
  }
}
