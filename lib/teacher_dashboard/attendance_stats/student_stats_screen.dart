import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/local_db_helper.dart';
import '../../models/student_model.dart';
import '../../constants/app_colors.dart';
import '../../models/student_with_division.dart';

class StudentStatsScreen extends StatefulWidget {
  final StudentWithDivision studentWithDivision;

  const StudentStatsScreen({super.key, required this.studentWithDivision});

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  List<DateTime> absentDates = [];
  int presentCount = 0;
  int absentCount = 0;
  Map<DateTime, String> reasons = {};

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final monthDate = DateTime.parse(selectedMonthDate());

    final records = await LocalDBHelper.instance.getAttendanceByStudentAndMonth(
      widget.studentWithDivision.student.id,
      monthDate,
    );

    int p = 0, a = 0;
    List<DateTime> absents = [];
    Map<DateTime, String> reasonsMap = {};

    for (final record in records) {
      if (record['is_present'] == 1) {
        p++;
      } else {
        a++;
        final date = DateTime.parse(record['date']);
        absents.add(date);
        if (record['reason'] != null) {
          reasonsMap[date] = record['reason'];
        }
      }
    }

    setState(() {
      presentCount = p;
      absentCount = a;
      absentDates = absents;
      reasons = reasonsMap;
    });
  }

  String selectedMonthDate() {
    final date = DateFormat('MMMM yyyy').parse(selectedMonth);
    return DateFormat('yyyy-MM-01').format(DateTime(date.year, date.month));
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      12,
          (index) => DateFormat('MMMM yyyy').format(DateTime(DateTime.now().year, index + 1)),
    );

    final student = widget.studentWithDivision.student;
    final divisionName = widget.studentWithDivision.divisionName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: selectedMonth,
                items: months
                    .map((month) => DropdownMenuItem(value: month, child: Text(month)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMonth = value;
                      loadAttendance();
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select Month',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Roll No: ${student.rollNumber} • $divisionName'),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: presentCount.toDouble(),
                            color: Colors.green,
                            showTitle: false, // Hides title inside the chart
                          ),
                          PieChartSectionData(
                            value: absentCount.toDouble(),
                            color: Colors.redAccent,
                            showTitle: false,
                          ),
                        ],
                        sectionsSpace: 4,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Present: $presentCount   •   Absent: $absentCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.grey.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: absentDates.isEmpty
                  ? const Text('✅ No absences this month.', style: TextStyle(fontSize: 16))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Absent Dates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (absentDates.isEmpty)
                    const Text(
                      'No absences recorded.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...absentDates.map((date) {
                      final formatted = DateFormat('dd MMM yyyy').format(date);
                      final reason = reasons[date];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: const Icon(Icons.calendar_today, color: Colors.redAccent),
                          title: Text(formatted),
                          subtitle: reason != null && reason.trim().isNotEmpty
                              ? Text("Reason: $reason")
                              : const Text("No reason provided", style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }),
                ],

              ),
            ),
          ),
        ],
      ),
    );
  }
}
