// import 'dart:io';
// import 'package:attendance_app_m2/services/local_db_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'views/auth/login_screen.dart';
// import 'dashboard/principal_dashboard.dart';
// import 'teacher_dashboard/teacher_dashboard.dart';
//
// class App extends StatelessWidget {
//   const App({super.key});
//
//   Future<Widget> getInitialScreen() async {
//     final session = Supabase.instance.client.auth.currentSession;
//
//     if (session != null) {
//       final userId = session.user.id;
//
//       try {
//         // Try online fetch
//         final profile = await Supabase.instance.client
//             .from('profiles')
//             .select('role')
//             .eq('id', userId)
//             .single();
//
//         final role = profile['role'];
//
//         if (role == 'principal') {
//           return const PrincipalDashboard();
//         } else if (role == 'teacher') {
//           return const TeacherDashboard();
//         } else {
//           return const LoginScreen(); // unknown role
//         }
//       } on SocketException {
//         // 👇 OFFLINE fallback to local DB
//         final localRole =
//         await LocalDBHelper.instance.getRoleForUser(userId);
//
//         if (localRole == 'principal') {
//           return const PrincipalDashboard();
//         } else if (localRole == 'teacher') {
//           return const TeacherDashboard();
//         } else {
//           return const LoginScreen(); // unknown or missing locally
//         }
//       } catch (e) {
//         debugPrint("❌ Unexpected error: $e");
//         return const UnknownErrorScreen();
//       }
//     } else {
//       return const LoginScreen(); // Not logged in
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Widget>(
//       future: getInitialScreen(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const MaterialApp(
//             home: Scaffold(body: Center(child: CircularProgressIndicator())),
//           );
//         }
//
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           home: snapshot.data ?? const UnknownErrorScreen(),
//         );
//       },
//     );
//   }
// }
// class NoInternetScreen extends StatelessWidget {
//   const NoInternetScreen({super.key});
//   Future<void> _checkInternetAndRetry(BuildContext context) async {
//     try {
//       // Try making a dummy request to check internet
//       final result = await InternetAddress.lookup('example.com');
//       if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//         // Internet is back — restart the app logic
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const App()),
//         );
//       }
//     } on SocketException {
//       // Still no internet; remain on screen
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Still no internet. Please try again.'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: RefreshIndicator(
//         onRefresh: () => _checkInternetAndRetry(context),
//         child: ListView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           children: const [
//             SizedBox(height: 200),
//             Center(
//               child: Column(
//                 children: [
//                   Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
//                   SizedBox(height: 20),
//                   Text(
//                     '⚠️ No Internet Connection.\nPull down to retry.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 18, color: Colors.redAccent),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class UnknownErrorScreen extends StatelessWidget {
//   const UnknownErrorScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text(
//           '❌ Something went wrong.\nPlease try again later.',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 18, color: Colors.red),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/local_db_helper.dart';
import 'teacher_dashboard/sync_helper.dart';
import 'views/auth/login_screen.dart';
import 'dashboard/principal_dashboard.dart';
import 'teacher_dashboard/teacher_dashboard.dart';


class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _initializeApp();
  }

  Future<Widget> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final session = Supabase.instance.client.auth.currentSession;

    try {
      final hasInternet = await _checkInternet();

      if (hasInternet) {
        // ✅ Supabase to local sync
        await LocalDBHelper.instance.syncDivisionsFromSupabase();
        await LocalDBHelper.instance.syncStudentsFromSupabase();
        await LocalDBHelper.instance.syncProfilesFromSupabase();
        //await LocalDBHelper.instance.syncAttendanceToSupabase();
        await LocalDBHelper.instance.getAllStudents();
        //await SyncHelper().syncAllAttendanceToSQLite();
        // final hasSyncedAttendance = prefs.getBool('has_synced_attendance') ?? false;
        // if (!hasSyncedAttendance) {
        //   await SyncHelper().syncAllAttendanceToSQLite();
        //   await prefs.setBool('has_synced_attendance', true);
        // }
      }

      if (session != null) {
        final userId = session.user.id;

        // Role logic
        String? role;
        if (hasInternet) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .single();
          role = profile['role'];
        } else {
          role = await LocalDBHelper.instance.getRoleForUser(userId);
        }

        switch (role) {
          case 'principal':
            return const PrincipalDashboard();
          case 'teacher':
            return const TeacherDashboard();
          default:
            return const LoginScreen();
        }
      } else {
        return const LoginScreen();
      }
    } on SocketException {
      return const NoInternetScreen(); // No internet fallback
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return const UnknownErrorScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );

        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.data ?? const UnknownErrorScreen(),
        );
      },
    );
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🎓 App Title or School Name
            Text(
              "Mini Miracle School",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),

            const SizedBox(height: 16),

            // 📱 Tagline / Purpose
            Text(
              "Smart Attendance System",
              style: TextStyle(
                fontSize: 18,
                color: Colors.deepPurple.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 40),

            // ⏳ Animated loader
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 20),

            // ⏱ Loading message
            Text(
              "Syncing with school server...",
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple.shade300,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  Future<void> _checkInternetAndRetry(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const App()),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still no internet. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _checkInternetAndRetry(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
              child: Column(
                children: [
                  Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
                  SizedBox(height: 20),
                  Text(
                    '⚠️ No Internet Connection.\nPull down to retry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class UnknownErrorScreen extends StatelessWidget {
  const UnknownErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '❌ Something went wrong.\nPlease try again later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}
