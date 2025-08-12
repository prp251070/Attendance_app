import 'dart:convert';
import 'dart:typed_data';
import 'package:attendance_app_m2/teacher_dashboard/sync_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 🔹 Added for DateFormat
import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../services/local_db_helper.dart';
import 'attendance_stats/attendance_export_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class MarkAttendanceScreen extends StatefulWidget {
  final String divisionId;
  final String divisionName;

  const MarkAttendanceScreen({
    super.key,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}
final GlobalKey _menuKey = GlobalKey();

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<StudentModel> students = [];
  Map<String, bool> attendanceStatus = {};
  DateTime selectedDate = DateTime.now(); // 🔹 1. Default selected date
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
    _syncFromSupabase();

  }
  void _syncFromSupabase() async {
    for (final student in await LocalDBHelper.instance.getStudentsByDivision(widget.divisionId)) {
      //await LocalDBHelper.instance.fetchAttendanceFromSupabaseAndCache(student.id);
    }
  }
  Future<void> _initData() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Step 1: Pull from Supabase to local SQLite for this division & date
    await SyncHelper().syncAttendanceFromSupabase(
      divisionId: widget.divisionId,
      date: formattedDate,
    );

    // Step 2: Now load data from local SQLite (students + attendance)
    await loadDataForDate(selectedDate);
  }
  Future<void> loadDataForDate(DateTime date) async {
    setState(() => isLoading = true);

    final dbHelper = LocalDBHelper();
    final allStudents = await dbHelper.getStudentsByDivision(widget.divisionId);
    allStudents.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final existingAttendance = await dbHelper.getAttendanceByDivisionAndDate(
      widget.divisionId,
      formattedDate,
    );

    final Map<String, bool> statusMap = {
      for (var student in allStudents) student.id: true, // default: present
    };

    for (var record in existingAttendance) {
      statusMap[record.studentId] = record.isPresent;
    }

    setState(() {
      selectedDate = date;
      students = allStudents;
      attendanceStatus = statusMap;
      isLoading = false;
    });
  }

  Future<void> generateAndShareAttendancePdf() async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text('Attendance Sheet', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Division: ${widget.divisionName}', style: pw.TextStyle(fontSize: 16)),
          pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Roll No', 'Name', 'Present'],
            data: students.map((student) {
              final present = attendanceStatus[student.id] ?? true;
              return [
                student.rollNumber.toString(),
                student.name,
                present ? 'Present' : 'Absent'
              ];
            }).toList(),
          ),
        ],
      ),
    );


    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void toggleAttendance(String studentId) {
    setState(() {
      attendanceStatus[studentId] = !(attendanceStatus[studentId] ?? true);
    });
  }

  // 🔹 1. Date picker function
  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      await loadDataForDate(picked); // <--- Load attendance for new date
    }
  }

  // 🔹 3. Updated submitAttendance with selectedDate
  // void submitAttendance() async {
  //   final dbHelper = LocalDBHelper();
  //
  //   final String formattedDate = selectedDate.toIso8601String().split('T').first;
  //
  //   final attendanceList = students.map((student) {
  //     final isPresent = attendanceStatus[student.id] ?? true;
  //
  //     return AttendanceModel(
  //       id: '${student.id}_$formattedDate',
  //       studentId: student.id,
  //       divisionId: widget.divisionId,
  //       date: formattedDate,
  //       isPresent: isPresent,
  //       isSync: false,
  //     );
  //   }).toList();
  //
  //   try {
  //     await dbHelper.insertAttendance(attendanceList);
  //     await dbHelper.debugPrintAllAttendance();
  //
  //     print("📝 Inserted attendance count: ${attendanceList.length}");
  //
  //     final unsynced = await dbHelper.getUnsyncedAttendance();
  //     print("⏳ Unsynced after insert: ${unsynced.length}");
  //
  //     await SyncHelper().syncAttendanceToSupabase();
  //
  //
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Attendance saved successfully.")),
  //     );
  //
  //     Navigator.pop(context); // Go back after saving
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error saving attendance: $e")),
  //     );
  //   }
  // }
  void submitAttendance() async {
    final dbHelper = LocalDBHelper();
    final String formattedDate = selectedDate.toIso8601String().split('T').first;

    final attendanceList = students.map((student) {
      final isPresent = attendanceStatus[student.id] ?? true;

      return {
        'student_id': student.id,
        'student_name': student.name,
        'roll_number': student.rollNumber,
        'is_present': isPresent,
        'date': formattedDate,
      };
    }).toList();

    final String fileName =
        '${widget.divisionName.replaceAll(" ", "_")}_${formattedDate.replaceAll("-", "_")}.json';

    final String jsonString = jsonEncode(attendanceList);
    final Uint8List fileBytes = utf8.encode(jsonString) as Uint8List;

    try {
      await Supabase.instance.client.storage
          .from('attendance-archives')
          .uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true), // overwrites if exists
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Attendance uploaded as JSON.")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to upload, Turn on Internet")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 🔹 2. Updated AppBar with date and calendar icon
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mark Attendance - ${widget.divisionName}"),
            Text(
              "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: _menuKey,
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              final RenderBox button = _menuKey.currentContext!.findRenderObject() as RenderBox;
              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

              final position = RelativeRect.fromRect(
                Rect.fromPoints(
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );

              final action = await showMenu(
                context: context,
                position: position,
                items: const [
                  PopupMenuItem(
                    value: 'pdf_attendance',
                    child: Text("Make PDF of Attendance"),
                  ),
                  PopupMenuItem(
                    value: 'export_attendance',
                    child: Text("📤 Export Attendance to Supabase Storage"),
                  ),
                  PopupMenuItem(
                    value: 'download_csv',
                    child: Text("📥 Download Attendance as CSV"),
                  ),
                ],
              );

              if (action == 'pdf_attendance') {
                await generateAndShareAttendancePdf();
              } else if (action == 'export_attendance') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceExportPage(
                      divisionId: widget.divisionId,
                      divisionName: widget.divisionName,
                      selectedDate: selectedDate,
                    ),
                  ),
                );
              } else if (action == 'download_csv') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceExportPage(
                      divisionId: widget.divisionId,
                      divisionName: widget.divisionName,
                      selectedDate: selectedDate,
                      downloadOnly: true,
                    ),
                  ),
                );
              }

              if (action == 'pdf_attendance') {
                await generateAndShareAttendancePdf();
              }
            },
          ),
        ],

        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Date and picker inside body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  tooltip: "Change Date",
                  onPressed: () => selectDate(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 🔹 Student List
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text("No students found."))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isPresent = attendanceStatus[student.id] ?? true;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      '${student.rollNumber}. ${student.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(student.email ?? ''),
                    trailing: Switch(
                      value: isPresent,
                      onChanged: (_) => toggleAttendance(student.id),
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red[200],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitAttendance,
        icon: const Icon(Icons.check),
        label: const Text("Save"),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
