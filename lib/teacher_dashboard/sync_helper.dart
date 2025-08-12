import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../models/attendance_model.dart';
import '../services/local_db_helper.dart';
import 'package:uuid/uuid.dart';
class SyncHelper {
  final _supabase = Supabase.instance.client;
  final _localDb = LocalDBHelper();

  Future<void> syncAttendanceFromSupabase({
    required String divisionId,
    required String date,
  }) async {
    final db = await _localDb.database;

    try {
      final division = await _localDb.getDivisionById(divisionId);
      if (division == null) {
        print("⚠️ Division not found locally for ID $divisionId");
        return;
      }

      final fileName = "${division.name}_${date.replaceAll('-', '_')}.json";

      final response = await _supabase.storage
          .from('attendance-archives') // ✅ Correct bucket
          .download(fileName); // ✅ No folder path

      if (response == null) {
        print("📭 No attendance file found for $fileName");
        return;
      }

      final content = await response;
      final decoded = jsonDecode(utf8.decode(content));

      final List<AttendanceModel> records = (decoded as List)
          .map((map) => AttendanceModel(
        id: map['id'] ?? const Uuid().v4(),
        studentId: map['student_id'] ?? '',
        divisionId: divisionId,
        date: map['date'] ?? '',
        isPresent: map['is_present'] ?? false,
        reason: map['reason'] ?? '', // 👈 fixes the error
        isSync: true,
      ))
          .toList();

      final batch = db.batch();
      for (final record in records) {
        batch.insert(
          'attendance',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      print("✅ Synced ${records.length} records from $fileName");
    } catch (e) {
      print("❌ Error syncing attendance JSON: $e");
    }
  }


  Future<void> syncAllAttendanceToSQLite() async {
    final db = await _localDb.database;

    try {
      final divisions = await _localDb.getAllDivisions();

      for (final division in divisions) {
        final files = await _supabase.storage
            .from('attendance-archives')  // ✅ corrected bucket name
            .list(); // ✅ assuming files are stored at root

        final relevantFiles =
        files.where((f) => f.name.startsWith(division.name)).toList();

        for (final file in relevantFiles) {
          try {
            final response = await _supabase.storage
                .from('attendance-archives') // ✅ corrected bucket name
                .download(file.name); // ✅ root-level download

            if (response == null) continue;

            final content = await response;
            final decoded = jsonDecode(utf8.decode(content));

            final List<AttendanceModel> records = (decoded as List)
                .map((map) => AttendanceModel(
              id: map['id'],
              studentId: map['student_id'],
              divisionId: division.id,
              date: map['date'],
              isPresent: map['is_present'],
              reason: map['reason'] ?? '',
              isSync: true,
            ))
                .toList();

            final batch = db.batch();
            for (final record in records) {
              batch.insert(
                'attendance-archives',
                record.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            await batch.commit(noResult: true);
          } catch (e) {
            print("⚠️ Skipped file ${file.name} due to error: $e");
          }
        }
      }

      print("✅ All attendance synced from Supabase Storage JSON to SQLite.");
    } catch (e) {
      print("❌ Error during full JSON sync: $e");
    }
  }
}
