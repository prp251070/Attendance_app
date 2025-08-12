import 'package:attendance_app_m2/teacher_dashboard/attendance_stats/attendanceViewerScreen.dart';
import 'package:flutter/material.dart';
import 'attendance_by_student_screen.dart';
import 'attendance_by_division_screen.dart';
import '../../constants/app_colors.dart';

class AttendanceStatsHome extends StatelessWidget {
  const AttendanceStatsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Statistics"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            // _StatCard(
            //   label: 'By Student',
            //   icon: Icons.person,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (_) => const AttendanceByStudentScreen()),
            //     );
            //   },
            // ),

            // _StatCard(
            //   label: 'By Division',
            //   icon: Icons.class_,
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           //builder: (_) => const AttendanceByDivisionScreen()),
            //           builder: (_) => const DivisionAttendanceListScreen()),
            //
            //     );
            //   },
            // ),
            _StatCard(
              label: 'Archieved',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AttendanceArchiveViewer()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.2), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
