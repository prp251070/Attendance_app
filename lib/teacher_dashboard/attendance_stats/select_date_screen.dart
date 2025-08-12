import 'package:flutter/material.dart';
import '../../services/local_db_helper.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SelectDateScreen extends StatefulWidget {
  final String divisionId;
  final String divisionName;

  const SelectDateScreen({
    super.key,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  DateTime? selectedDate;
  List<StudentModel> absentStudents = [];
  int totalPresent = 0;
  int totalAbsent = 0;
  bool isLoading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      await _loadAttendanceData(picked);
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAttendanceData(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final attendanceList = await LocalDBHelper.instance.getAttendanceByDivisionAndDate(
      widget.divisionId,
      formattedDate,
    );

    if (attendanceList.isEmpty) {
      setState(() {
        totalPresent = 0;
        totalAbsent = 0;
        absentStudents = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance not marked for this date.")),
      );
      return;
    }

    final students = await LocalDBHelper.instance.getStudentsByDivision(widget.divisionId);
    final presentIds = attendanceList.where((a) => a.isPresent).map((a) => a.studentId).toSet();
    final absent = students.where((s) => !presentIds.contains(s.id)).toList();

    final absentWithReason = absent.map((s) {
      final record = attendanceList.firstWhere(
            (a) => a.studentId == s.id,
        orElse: () => AttendanceModel(
          id: '',
          studentId: s.id,
          divisionId: widget.divisionId,
          date: formattedDate,
          isPresent: false,
          reason: '',
          isSync: true,
        ),
      );
      s.reason = record.reason ?? '';
      return s;
    }).toList();

    setState(() {
      totalPresent = presentIds.length;
      totalAbsent = absentWithReason.length;
      absentStudents = absentWithReason;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.divisionName} Attendance"),
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text("Select Date"),
              ),
            ),
            const SizedBox(height: 20),
            if (selectedDate != null && !isLoading)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: totalPresent.toDouble(),
                                        color: Colors.green,
                                        title: '$totalPresent\nPresent',
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: totalAbsent.toDouble(),
                                        color: Colors.redAccent,
                                        title: '$totalAbsent\nAbsent',
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                    sectionsSpace: 4,
                                    centerSpaceRadius: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (absentStudents.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            " Absent Students",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...absentStudents.map((s) => Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.person_off, color: Colors.redAccent),
                            title: Text(s.name),
                            subtitle: Text("Reason: ${(s.reason ?? '').isEmpty ? 'No reason' : s.reason}"),
                          ),
                        )),
                      ] else
                        const Text(" No absentees!"),
                    ],
                  ),
                ),
              )
            else if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              const Center(child: Text("Please select a date to view attendance.")),
          ],
        ),
      ),
    );
  }
}
