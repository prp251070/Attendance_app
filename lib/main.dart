// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'app.dart';// Handles routing and theme
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:sqflite/sqflite.dart';
// import 'services/local_db_helper.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'constants/supabase_constants.dart'; // Store your Supabase keys here safely
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: 'https://peuhhsyxyklzfaxdvhpp.supabase.co',
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBldWhoc3l4eWtsemZheGR2aHBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMDMyMjksImV4cCI6MjA2Mjg3OTIyOX0._VvkSLzPE5K_qKmlp8WMsvfAQpHQizS7oUVmP5jvOO0',
//   );
//   // await LocalDBHelper().init();
//   // await LocalDBHelper.instance.syncDivisionsFromSupabase();
//   // await LocalDBHelper.instance.syncStudentsFromSupabase();// We'll define this next
//   // await LocalDBHelper.instance.printAllLocalData();
//   // await LocalDBHelper.instance.syncAttendanceToSupabase();
//   // await LocalDBHelper.instance.getAllStudents();
//   //
//   // runApp(MyApp(hasInternet: hasInternet));
//   // Initialize SQLite
//   await LocalDBHelper().init();
//
//   // Check internet connectivity
//   final connectivityResult = await Connectivity().checkConnectivity();
//   final hasInternet = connectivityResult != ConnectivityResult.none;
//
//   if (hasInternet) {
//     try {
//       await LocalDBHelper.instance.syncDivisionsFromSupabase();
//       await LocalDBHelper.instance.syncStudentsFromSupabase();
//       await LocalDBHelper.instance.syncAttendanceToSupabase();
//       await LocalDBHelper.instance.getAllStudents();
//     } catch (e) {
//       debugPrint('❌ Supabase sync failed: $e');
//     }
//   } else {
//     debugPrint('📴 No internet. Skipping Supabase sync.');
//   }
//
//   // Always load local data
//   await LocalDBHelper.instance.printAllLocalData();
//
//   runApp(MyApp(hasInternet: hasInternet));
// }
// /// Root of the application.
// ///Calls [MyApp] which is defined in app.dart
// ///
//
// class MyApp extends StatelessWidget {
//   final bool hasInternet;
//   const MyApp({super.key, required this.hasInternet});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "School Attendance App",
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//       ),
//       home: hasInternet ? const App() : const NoInternetScreen(),
//     );
//   }
// }
//
//
// class NoInternetScreen extends StatelessWidget {
//   const NoInternetScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
//             const SizedBox(height: 16),
//             const Text(
//               'No Internet Connection',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Please turn on your internet to sync with Supabase.',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 // Restart the app logic — optional
//                 main();
//               },
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:attendance_app_m2/teacher_dashboard/sync_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'app.dart'; // App handles routing and session role logic
// import 'services/local_db_helper.dart';
// import 'constants/supabase_constants.dart';
//
// import 'services/local_db_helper.dart';
// import 'app.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Supabase.initialize(
//     url: 'https://peuhhsyxyklzfaxdvhpp.supabase.co',
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBldWhoc3l4eWtsemZheGR2aHBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczMDMyMjksImV4cCI6MjA2Mjg3OTIyOX0._VvkSLzPE5K_qKmlp8WMsvfAQpHQizS7oUVmP5jvOO0',
//   );
//
//   await LocalDBHelper().init();
//
//   final hasInternet = await checkInternetConnection();
//   final prefs = await SharedPreferences.getInstance();
//
//
//   if (hasInternet) {
//     try {
//       // Always sync other tables like divisions, students, profiles (lightweight)
//       await LocalDBHelper.instance.syncDivisionsFromSupabase();
//       await LocalDBHelper.instance.syncStudentsFromSupabase();
//       await LocalDBHelper.instance.syncProfilesFromSupabase();
//
//       // Sync any pending local attendance to Supabase
//       await LocalDBHelper.instance.syncAttendanceToSupabase();
//
//       // ✅ Attendance sync only once (on first app run)
//       final hasSyncedAttendance = prefs.getBool('has_synced_attendance') ?? false;
//
//       if (!hasSyncedAttendance) {
//         print("📡 First time: syncing attendance from Supabase");
//         await SyncHelper().syncAllAttendanceToSQLite();
//         await prefs.setBool('has_synced_attendance', true);
//       } else {
//         print("✅ Attendance already synced. Using local DB.");
//       }
//     } catch (e) {
//       debugPrint('❌ Supabase sync failed: $e');
//     }
//   } else {
//     debugPrint('📴 No internet. Skipping Supabase sync.');
//   }
//
//   runApp(MyApp(hasInternet: hasInternet));
// }
//
// /// Check for internet connection
// Future<bool> checkInternetConnection() async {
//   final result = await Connectivity().checkConnectivity();
//   return result != ConnectivityResult.none;
// }
//
// /// App entry widget
// class MyApp extends StatelessWidget {
//   final bool hasInternet;
//   const MyApp({super.key, required this.hasInternet});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "School Attendance App",
//       theme: ThemeData(primarySwatch: Colors.deepPurple),
//       home: hasInternet ? const App() : const NoInternetScreen(),
//     );
//   }
// }
//
// /// Offline fallback screen
// class NoInternetScreen extends StatefulWidget {
//   const NoInternetScreen({super.key});
//
//   @override
//   State<NoInternetScreen> createState() => _NoInternetScreenState();
// }
//
// class _NoInternetScreenState extends State<NoInternetScreen> {
//   bool isRefreshing = false;
//
//   Future<void> _checkAndRetry() async {
//     setState(() => isRefreshing = true);
//     final hasInternet = await checkInternetConnection();
//
//     if (hasInternet) {
//       main(); // Relaunch logic
//     } else {
//       setState(() => isRefreshing = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: RefreshIndicator(
//         onRefresh: _checkAndRetry,
//         child: ListView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           children: [
//             SizedBox(
//               height: MediaQuery.of(context).size.height * 0.8,
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'No Internet Connection',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Please turn on your internet to sync with Supabase.',
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: _checkAndRetry,
//                       icon: const Icon(Icons.refresh),
//                       label: isRefreshing
//                           ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                           : const Text('Retry'),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/local_db_helper.dart';
import 'app.dart';
import 'package:permission_handler/permission_handler.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '',
    anonKey: '');
  await Permission.manageExternalStorage.request();

  await LocalDBHelper().init();

  runApp(const MyApp()); // 🔥 Run app immediately
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Attendance App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const App(), // App handles routing + syncing
    );
  }
}
