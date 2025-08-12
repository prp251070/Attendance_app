import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app_m2/services/local_db_helper.dart'; // adjust path to your DB helper

import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AttendanceExportPage extends StatefulWidget {
  final String divisionId;
  final String divisionName;
  final DateTime selectedDate;
  final bool downloadOnly;

  const AttendanceExportPage({
    Key? key,
    required this.divisionId,
    required this.divisionName,
    required this.selectedDate,
    this.downloadOnly = false,
  }) : super(key: key);

  @override
  State<AttendanceExportPage> createState() => _AttendanceExportPageState();
}

class _AttendanceExportPageState extends State<AttendanceExportPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isProcessing = false;
  String statusMessage = '';

  /// Fetch attendance data from local SQLite
  Future<List<Map<String, dynamic>>> _fetchAttendanceFromSQLite() async {
    final db = await LocalDBHelper.instance.database;
    final formattedMonth = DateFormat('yyyy-MM').format(widget.selectedDate);

    // Step 1: Fetch attendance for selected month & division
    final rawAttendance = await db.query(
      'attendance',
      where: "division_id = ? AND strftime('%Y-%m', date) = ?",
      whereArgs: [widget.divisionId, formattedMonth],
    );

    // Step 2: Fetch all students of that division
    final students = await db.query(
      'students',
      where: "division_id = ?",
      whereArgs: [widget.divisionId],
    );

    final studentMap = {
      for (var s in students) s['id']: s
    };

    // Step 3: Fetch division name
    final division = await db.query(
      'divisions',
      where: "id = ?",
      whereArgs: [widget.divisionId],
      limit: 1,
    );
    final divisionName = division.isNotEmpty ? division.first['name'] : 'Unknown';

    // Step 4: Merge data
    final enriched = rawAttendance.map((att) {
      final student = studentMap[att['student_id']] ?? {};
      return {
        'student_name': student['name'] ?? 'Unknown',
        'roll_number': student['roll_number'] ?? '',
        'division_name': divisionName,
        'date': att['date'],
        'is_present': att['is_present'],
        'reason': att['reason'] ?? '',
      };
    }).toList();

    return enriched;
  }


  /// Upload JSON file to Supabase Storage
  Future<void> _uploadJsonToSupabase(List<Map<String, dynamic>> data) async {
    final jsonString = jsonEncode(data);
    final filename =
        '${widget.divisionName}_${DateFormat('yyyy_MM').format(widget.selectedDate)}.json';

    setState(() {
      statusMessage = 'Uploading to Supabase Storage...';
      isProcessing = true;
    });

    try {
      await supabase.storage
          .from('attendance-archives')
          .uploadBinary(filename, utf8.encode(jsonString), fileOptions: const FileOptions(
        upsert: true,
        contentType: 'application/json',
      ));

      setState(() {
        statusMessage = '✅ JSON file uploaded to Supabase Storage.';
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = '❌ Failed to upload: $e';
        print(e);
        isProcessing = false;
      });
    }
  }

  /// Download JSON file and convert to CSV
  Future<void> _downloadJsonAndConvertToCsv() async {
    final filename =
        '${widget.divisionName}_${DateFormat('yyyy_MM').format(widget.selectedDate)}.json';

    setState(() {
      isProcessing = true;
      statusMessage = 'Downloading JSON from Supabase...';
    });

    try {
      final response = await supabase.storage
          .from('attendance-archives')
          .download(filename);

      if (response.isEmpty) throw 'No data found';

      final jsonString = utf8.decode(response);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Map<String, dynamic>> rawAttendance =
      List<Map<String, dynamic>>.from(jsonList);

      // Fetch student and division data from local DB
      final db = await LocalDBHelper.instance.database;
      final students = await db.query(
        'students',
        where: "division_id = ?",
        whereArgs: [widget.divisionId],
      );
      final studentMap = {
        for (var s in students) s['id']: s,
      };

      final division = await db.query(
        'divisions',
        where: "id = ?",
        whereArgs: [widget.divisionId],
        limit: 1,
      );
      final divisionName = division.isNotEmpty ? division.first['name'] : 'Unknown';

      // Enrich the raw data
      final enriched = rawAttendance.map((att) {
        final student = studentMap[att['student_id']] ?? {};
        return {
          'student_name': student['name'] ?? 'Unknown',
          'roll_number': student['roll_number'] ?? '',
          'division_name': divisionName,
          'date': att['date'],
          'is_present': att['is_present'],
          'reason': att['reason'] ?? '',
        };
      }).toList();

      final csvData = _convertJsonToCsv(enriched);

      // 👇 Add file picker + permission
      if (await Permission.manageExternalStorage.request().isGranted) {
        final savePath = await FilePicker.platform.getDirectoryPath();

        if (savePath != null) {
          final filePath =
              '$savePath/${widget.divisionName}_${DateFormat('yyyy_MM').format(widget.selectedDate)}.csv';

          final file = File(filePath);
          await file.writeAsString(csvData);

          setState(() {
            statusMessage = '✅ CSV file saved at:\n$filePath';
            isProcessing = false;
          });
        } else {
          setState(() {
            statusMessage = '⚠️ No folder selected.';
            isProcessing = false;
          });
        }
      } else {
        setState(() {
          statusMessage = '❌ Storage permission denied.';
          isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = '❌ Error downloading or saving: $e';
        isProcessing = false;
      });
    }
  }



  /// Converts List<Map<String, dynamic>> to CSV
  String _convertJsonToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    final headers = data.first.keys;
    final csv = StringBuffer();
    csv.writeln(headers.join(','));
    for (final row in data) {
      csv.writeln(headers.map((h) => '"${row[h] ?? ""}"').join(','));
    }
    return csv.toString();
  }

  /// Master controller based on downloadOnly flag
  Future<void> _handleAction() async {
    if (widget.downloadOnly) {
      await _downloadJsonAndConvertToCsv();
    } else {
      final attendance = await _fetchAttendanceFromSQLite();
      if (attendance.isEmpty) {
        setState(() {
          statusMessage = '⚠️ No attendance data found for this month.';
        });
        return;
      }
      await _uploadJsonToSupabase(attendance);
    }
  }

  @override
  void initState() {
    super.initState();
    _handleAction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Export'),
      ),
      body: Center(
        child: isProcessing
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            statusMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
