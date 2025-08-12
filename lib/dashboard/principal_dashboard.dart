import 'package:attendance_app_m2/identity_option/student_list.dart';
import 'package:attendance_app_m2/teacher_dashboard/attendance_stats/attendance_stats_home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/auth/login_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../views/principal/students/add_student_screen.dart';
import 'division_list_screen.dart';
import '../identity_option/student_list.dart';

class PrincipalDashboard extends StatelessWidget {
  const PrincipalDashboard({super.key});

  void handleLogout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
  void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                handleLogout(context); // Proceed with logout
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Principal Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF6EC6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildDashboardCard(
                icon: Icons.people,
                label: 'Manage Students',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DivisionListScreen()),
                  );
                },
              ),
              // _buildDashboardCard(
              //   icon: Icons.person_add,
              //   label: 'Add Teachers',
              //   onTap: () {
              //     // TODO: Add teacher screen navigation
              //   },
              // ),
              _buildDashboardCard(
                icon: Icons.event_available,
                label: 'View Attendance',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_)=> AttendanceStatsHome()),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.perm_identity,
                label: 'Identity',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudentListScreen()),
                  );
                },
              ),
              // _buildDashboardCard(
              //   icon: Icons.settings,
              //   label: 'Settings',
              //   onTap: () {
              //     // TODO: Settings screen
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _pressed = false;

  @override
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(4, 6),
                blurRadius: 12,
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                offset: const Offset(-2, -2),
                blurRadius: 8,
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withOpacity(0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  widget.icon,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.label,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.3,
                  color: Colors.black87,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      offset: const Offset(0.2, 0.2),
                      blurRadius: 1,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
