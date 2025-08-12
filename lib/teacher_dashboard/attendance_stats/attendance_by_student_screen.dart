import 'package:flutter/material.dart';
import '../../models/student_with_division.dart';
import '../../services/local_db_helper.dart';
import '../../models/student_model.dart';
import 'student_stats_screen.dart';
import '../../constants/app_colors.dart';

class AttendanceByStudentScreen extends StatefulWidget {
  const AttendanceByStudentScreen({super.key});

  @override
  State<AttendanceByStudentScreen> createState() =>
      _AttendanceByStudentScreenState();
}

class _AttendanceByStudentScreenState
    extends State<AttendanceByStudentScreen> {
  Map<String, List<StudentWithDivision>> divisionWiseStudents = {};


  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final rawStudents = await LocalDBHelper.instance.getAllStudentsWithDivision();

    final Map<String, List<StudentWithDivision>> grouped = {};

    for (final raw in rawStudents) {
      final divisionName = raw['division_name'] ?? 'Unknown';
      final student = StudentModel.fromMap(raw);

      grouped.putIfAbsent(divisionName, () => []);
      grouped[divisionName]!.add(StudentWithDivision(
        student: student,
        divisionName: divisionName,
      ));
    }

    setState(() {
      divisionWiseStudents = grouped;
    });
  }


  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students by Division'),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: divisionWiseStudents.length,
        itemBuilder: (context, index) {
          final divisionName = divisionWiseStudents.keys.elementAt(index);
          final students = divisionWiseStudents[divisionName]!;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  divisionName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                iconColor: AppColors.primary,
                collapsedIconColor: Colors.grey,
                children: students.map((studentWithDivision) {
                  final student = studentWithDivision.student;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Roll No: ${student.rollNumber}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentStatsScreen(
                              studentWithDivision: studentWithDivision,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
