import 'package:sqflite/sqflite.dart';
import 'local_db_helper.dart';
import '../models/division_model.dart';

class DivisionLocalService {
  static final DivisionLocalService _instance = DivisionLocalService._internal();
  factory DivisionLocalService() => _instance;
  DivisionLocalService._internal();

  // INSERT or UPDATE (upsert)
  Future<void> upsertDivision(DivisionModel division) async {
    final db = await LocalDBHelper().database;
    await db.insert(
      'divisions',
      division.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  // ADD this in division_local_service.dart
  Future<void> insertAllDivisions(List<DivisionModel> divisions) async {
    final db = await LocalDBHelper().database;
    final batch = db.batch();

    for (final division in divisions) {
      batch.insert(
        'divisions',
        division.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }


  // FETCH all divisions
  Future<List<DivisionModel>> getAllDivisions() async {
    final db = await LocalDBHelper().database;
    final result = await db.query('divisions');

    return result.map((row) => DivisionModel.fromMap(row)).toList();
  }

  // FETCH single division by ID
  Future<DivisionModel?> getDivisionById(String id) async {
    final db = await LocalDBHelper().database;
    final result = await db.query(
      'divisions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return DivisionModel.fromMap(result.first);
    }
    return null;
  }

  // DELETE a division
  Future<void> deleteDivision(String id) async {
    final db = await LocalDBHelper().database;
    await db.delete(
      'divisions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CLEAR all divisions (utility)
  Future<void> clearAllDivisions() async {
    final db = await LocalDBHelper().database;
    await db.delete('divisions');
  }
}
