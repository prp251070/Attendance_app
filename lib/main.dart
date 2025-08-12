
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

  runApp(const MyApp()); //  Run app immediately
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
