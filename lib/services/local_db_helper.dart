  // local_db_helper.dart
  import 'dart:io';
  import 'package:sqflite/sqflite.dart';
  import 'package:path/path.dart';
  import '../models/attendance_model.dart';
import '../models/division_model.dart';
  import '../models/student_model.dart';
  import '../constants/supabase_constants.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:flutter/foundation.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:http/http.dart' as http;

  class LocalDBHelper {
    static final LocalDBHelper _instance = LocalDBHelper._internal();

    static LocalDBHelper get instance => _instance;

    factory LocalDBHelper() => _instance;

    LocalDBHelper._internal();

    static Database? _db;

    Future<Database> get database async {
      if (_db != null) return _db!;
      _db = await _initDB();
      return _db!;
    }

    Future<Database> _initDB() async {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'school_attendance.db');
      //await deleteDatabase(path);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    }

    Future<void> _onCreate(Database db, int version) async {
      await db.execute('''
        CREATE TABLE profiles (
          id TEXT PRIMARY KEY,
          email TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE divisions (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE students (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          roll_number INTEGER NOT NULL,
          date_of_birth TEXT,
          blood_group TEXT,
          address TEXT,
          contact TEXT,
          parent_contact TEXT,
          email TEXT,
          photo_url TEXT,
          photo_local_path TEXT,
          division_id TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          is_synced INTEGER DEFAULT 0,
          FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          division_id TEXT NOT NULL,
          date TEXT NOT NULL,
          is_present INTEGER NOT NULL,
          reason TEXT,
          is_sync INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
          FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE CASCADE
        )
      ''');


    }

    Future<void> clearAllData() async {
      final db = await database;
      await db.delete('students');
      await db.delete('divisions');
      await db.delete('profiles');
    }

    Future<void> init() async {
      await database; // Initializes _db if null
    }

    /// Insert a division into the local SQLite DB
    Future<void> insertDivision(DivisionModel division) async {
      final db = await database;
      await db.insert(
        'divisions',
        division.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    /// Update a division
    Future<void> updateDivision(DivisionModel division) async {
      final db = await database;
      await db.update(
        'divisions',
        division.toMap(),
        where: 'id = ?',
        whereArgs: [division.id],
      );
    }

    /// Delete a division
    Future<void> deleteDivision(String id) async {
      final db = await database;
      await db.delete(
        'divisions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    /// Get all divisions from local DB
    Future<List<DivisionModel>> getAllDivisions() async {
      final db = await database;
      final result = await db.query('divisions', orderBy: 'name ASC');
      return result.map((e) => DivisionModel.fromMap(e)).toList();
    }
    Future<void> deleteStudentsByDivision(String divisionId) async {
      final db = await database;
      await db.delete(
        'students',
        where: 'division_id = ?',
        whereArgs: [divisionId],
      );
    }


    Future<bool> studentExists(String name, [String? email]) async {
      final db = await instance.database;
      final result = await db.query(
        'students',
        where: email != null ? 'name = ? AND email = ?' : 'name = ?',
        whereArgs: email != null ? [name, email] : [name],
      );
      return result.isNotEmpty;
    }
    Future<DivisionModel?> getDivisionById(String divisionId) async {
      final db = await database;
      final maps = await db.query(
        'divisions',
        where: 'id = ?',
        whereArgs: [divisionId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return DivisionModel.fromMap(maps.first);
      }
      return null;
    }

    Future<void> syncDivisionsFromSupabase() async {
      try {
        final supabase = Supabase.instance.client;
        final data = await supabase.from(SupabaseConstants.divisionsTable).select();

        final db = await database;

        for (final division in data) {
          await db.insert(
            SupabaseConstants.divisionsTable,
            {
              SupabaseConstants.columnId: division[SupabaseConstants.columnId],
              SupabaseConstants.columnName: division[SupabaseConstants.columnName],
              SupabaseConstants.columnCreatedAt: division[SupabaseConstants.columnCreatedAt],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        debugPrint('✅ Divisions synced from Supabase to SQLite');
      } catch (e) {
        debugPrint('❌ Error syncing divisions: $e');
      }
    }


    Future<void> syncStudentsFromSupabase() async {
      try {
        final supabase = Supabase.instance.client;
        final data = await supabase.from(SupabaseConstants.studentsTable).select();
        final db = await database;

        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${appDir.path}/students_images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        for (final student in data) {
          String? photoUrl = student[SupabaseConstants.columnPhotoUrl];
          String? localPath;

          // 👇 Download image locally if photo URL exists
          if (photoUrl != null && photoUrl.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(photoUrl));
              if (response.statusCode == 200) {
                final fileName = '${student[SupabaseConstants.columnId]}.jpg';
                final filePath = '${imageDir.path}/$fileName';
                final file = File(filePath);
                await file.writeAsBytes(response.bodyBytes);
                localPath = filePath;
              }
            } catch (e) {
              debugPrint('❌ Error downloading image: $e');
            }
          }

          await db.insert(
            SupabaseConstants.studentsTable,
            {
              SupabaseConstants.columnId: student[SupabaseConstants.columnId],
              SupabaseConstants.columnName: student[SupabaseConstants.columnName],
              SupabaseConstants.columnRollNumber: student[SupabaseConstants.columnRollNumber],
              SupabaseConstants.columnDateOfBirth: student[SupabaseConstants.columnDateOfBirth],
              SupabaseConstants.columnBloodGroup: student[SupabaseConstants.columnBloodGroup],
              SupabaseConstants.columnAddress: student[SupabaseConstants.columnAddress],
              SupabaseConstants.columnContact: student[SupabaseConstants.columnContact],
              SupabaseConstants.columnParentContact: student[SupabaseConstants.columnParentContact],
              SupabaseConstants.columnEmail: student[SupabaseConstants.columnEmail],
              SupabaseConstants.columnPhotoUrl: photoUrl,
              'photo_local_path': localPath,
              SupabaseConstants.columnDivisionId: student[SupabaseConstants.columnDivisionId],
              SupabaseConstants.columnCreatedAt: student[SupabaseConstants.columnCreatedAt],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        debugPrint('✅ Students synced from Supabase to SQLite with local image caching');
      } catch (e) {
        debugPrint('❌ Error syncing students: $e');
      }
    }
    Future<void> printAllLocalData() async {
      final db = await database;

      final divisions = await db.query('divisions');
      final students = await db.query('students');

      debugPrint('📦 Divisions in SQLite:');
      for (var d in divisions) {
        debugPrint(d.toString());
      }

      debugPrint('🎓 Students in SQLite:');
      for (var s in students) {
        debugPrint(s.toString());
      }
    }
    Future<int> updateStudent(Map<String, dynamic> student) async {
      final db = await database;

      String? photoUrl = student['photo_url'];
      String? localPath;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(photoUrl));
          if (response.statusCode == 200) {
            final appDir = await getApplicationDocumentsDirectory();
            final imageDir = Directory('${appDir.path}/students_images');
            if (!await imageDir.exists()) {
              await imageDir.create(recursive: true);
            }

            final fileName = '${student['id']}.jpg';
            final filePath = '${imageDir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            localPath = filePath;
            student['photo_local_path'] = localPath; // ✅ Update local path in student map
          }
        } catch (e) {
          debugPrint('❌ Error updating student image: $e');
        }
      }

      return db.update(
        'students',
        student,
        where: 'id = ?',
        whereArgs: [student['id']],
      );
    }
    Future<List<StudentModel>> getStudentsByDivision(String divisionId) async {
      final db = await database;
      final result = await db.query(
        'students',
        where: 'division_id = ?',
        whereArgs: [divisionId],
        orderBy: 'roll_number ASC',
      );
      return result.map((e) => StudentModel.fromMap(e)).toList();
    }
    Future<void> insertAttendance(List<AttendanceModel> records) async {
      final db = await database;
      final batch = db.batch();

      for (var record in records) {
        print("📥 Inserting for student ${record.studentId} on ${record.date}, isSync: ${record.isSync}");
        batch.insert(
          'attendance',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      //print('✅ Attendance inserted into local DB for date: ${records.first.date}');
    }

    Future<List<AttendanceModel>> getAttendanceForDivision(String divisionId, String date) async {
      final db = await database;
      final maps = await db.query(
        'attendance',
        where: 'division_id = ? AND date = ?',
        whereArgs: [divisionId, date],
      );

      return maps.map((map) => AttendanceModel.fromMap(map)).toList();
    }

    Future<List<AttendanceModel>> getUnsyncedAttendance() async {
      final db = await database;
      final maps = await db.query(
        'attendance',
        where: 'is_sync = 0',
      );
      print("🔍 Found ${maps.length} unsynced attendance records");
      return maps.map((map) => AttendanceModel.fromMap(map)).toList();
    }

    Future<List<AttendanceModel>> getAttendanceByDivisionAndDate(String divisionId, String date) async {
      final db = await database;
      final result = await db.query(
        'attendance',
        where: 'division_id = ? AND date = ?',
        whereArgs: [divisionId, date],
      );

      return result.map((e) => AttendanceModel.fromMap(e)).toList();
    }



    Future<void> markAttendanceAsSynced(String id) async {
      final db = await database;
      await db.update(
        'attendance',
        {'is_sync': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    Future<void> syncAttendanceToSupabase() async {
      final supabase = Supabase.instance.client;
      final db = await database;
      final unsyncedAttendance = await getUnsyncedAttendance();

      for (final attendance in unsyncedAttendance) {
        try {
          await supabase.from('attendance').upsert({
            'id': attendance.id,
            'student_id': attendance.studentId,
            'division_id': attendance.divisionId,
            'date': attendance.date,
            'is_present': attendance.isPresent,
            'reason':attendance.reason,
          });

          // After successful sync, update local is_sync to true
          await db.update(
            'attendance',
            {'is_sync': 1},
            where: 'id = ?',
            whereArgs: [attendance.id],
          );

        } catch (e) {
          debugPrint('❌ Error syncing ${attendance.id}: $e');
        }
      }

      debugPrint('✅ Synced ${unsyncedAttendance.length} attendance records to Supabase');
    }



    Future<List<Map<String, dynamic>>> getAttendanceByStudentAndMonth(String studentId, DateTime month) async {
      final db = await instance.database;

      // Get the first and last day of the month
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final result = await db.query(
        'attendance',
        where: 'student_id = ? AND date BETWEEN ? AND ?',
        whereArgs: [
          studentId,
          firstDay.toIso8601String().split('T')[0],
          lastDay.toIso8601String().split('T')[0],
        ],
        orderBy: 'date ASC',
      );

      return result;
    }
    Future<List<Map<String, dynamic>>> getAllStudentsWithDivision() async {
      final db = await instance.database;

      final result = await db.rawQuery('''
    SELECT students.*, divisions.name AS division_name
    FROM students
    INNER JOIN divisions ON students.division_id = divisions.id
    ORDER BY divisions.name ASC, students.roll_number ASC
  ''');

      return result;
    }

    Future<void> fetchAttendanceFromSupabaseAndCache(String studentId) async {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('attendance')
          .select()
          .eq('student_id', studentId); // Now studentId is defined

      final attendanceList = (response as List).map((item) {
        return AttendanceModel(
          id: item['id'],
          studentId: item['student_id'],
          divisionId: item['division_id'],
          date: item['date'],
          isPresent: item['is_present'],
          reason: item['reason'],
          isSync: true,
        );
      }).toList();

      await LocalDBHelper.instance.insertAttendance(attendanceList);
    }
    Future<void> debugPrintAllAttendance() async {
      final db = await database;
      final records = await db.query('attendance');

      print("🗂️ Local Attendance Records:");
      for (final row in records) {
        print(row);
      }
    }
    Future<List<StudentModel>> getAllStudents() async {
      final db = await database;
      final result = await db.query('students');
      return result.map((e) => StudentModel.fromMap(e)).toList();
    }



    Future<void> syncAllAttendanceFromSupabase() async {
      final students = await LocalDBHelper.instance.getAllStudents();
      for (final student in students) {
        await LocalDBHelper.instance.fetchAttendanceFromSupabaseAndCache(student.id);
      }
    }
    Future<void> saveProfileLocally({
      required String id,
      required String email,
      required String role,
    }) async {
      final db = await instance.database;
      await db.insert(
        'profiles',
        {
          'id': id,
          'email': email,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    Future<Map<String, dynamic>?> getSavedProfile() async {
      final db = await instance.database;
      final result = await db.query('profiles', limit: 1);
      return result.isNotEmpty ? result.first : null;
    }
    Future<String?> getRoleForUser(String userId) async {
      final db = await instance.database;
      final result = await db.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['role'] as String?;
      }
      return null;
    }
    Future<void> syncProfilesFromSupabase() async {
      final db = await database;

      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('*');

        final List<dynamic> profiles = response;

        // Clear existing local profiles
        await db.delete('profiles');

        // Insert fresh data
        for (var profile in profiles) {
          await db.insert('profiles', {
            'id': profile['id'],
            'email': profile['email'],
            'role': profile['role'],
            'created_at': profile['created_at'],
          });
        }

        debugPrint('✅ Profiles synced from Supabase to SQLite.');
      } catch (e) {
        debugPrint('❌ Failed to sync profiles: $e');
      }
    }

  }


