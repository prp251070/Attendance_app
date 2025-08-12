import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../dashboard/principal_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/local_db_helper.dart';
import '../../teacher_dashboard/teacher_dashboard.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  void handleLogin() async {
    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim(); // not used yet, see note below

    try {
      final result = await InternetAddress.lookup('example.com');
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (hasInternet) {
        // ONLINE LOGIN
        final response = await AuthService.login(email, password);

        if (response != null && response.user != null) {
          final userId = response.user!.id;

          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .single();

          final role = profile['role'];

          // ✅ Navigate based on role
          if (role == 'principal') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PrincipalDashboard()));
          } else if (role == 'teacher') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboard()));
          } else {
            showSnackbar('Unknown role');
          }
        } else {
          showSnackbar('Invalid credentials');
        }
      } else {
        // OFFLINE LOGIN
        final db = await LocalDBHelper.instance.database;
        final result = await db.query(
          'profiles',
          where: 'email = ?',
          whereArgs: [email],
          limit: 1,
        );

        if (result.isNotEmpty) {
          final localUser = result.first;
          final role = localUser['role'] as String;

          // ✅ Navigate based on local role
          if (role == 'principal') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PrincipalDashboard()));
          } else if (role == 'teacher') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboard()));
          } else {
            showSnackbar('Unknown role');
          }
        } else {
          showSnackbar('User not found in offline cache');
        }
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      showSnackbar('Something went wrong. Try again.');
    }

    setState(() => isLoading = false);
  }
  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Image.asset(
              'lib/assets/logo.jpg', // Add your logo to assets folder
              height: 160,
            ),
            const SizedBox(height: 10),
            const Text(
              'School Attendance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            const Text(
              'Department of School Education',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.brown[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Digital Attendance Monitor System',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: 'EMAIL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: 'PASSWORD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: handleLogin,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LOGIN', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
