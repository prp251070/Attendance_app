import 'package:flutter/material.dart';
import '../models/division_model.dart';
import '../services/local_db_helper.dart';
import '../teacher_dashboard/mark_attendance_screen.dart'; // Update this import path as needed

class SelectDivisionScreen extends StatefulWidget {
  const SelectDivisionScreen({super.key});

  @override
  State<SelectDivisionScreen> createState() => _SelectDivisionScreenState();
}

class _SelectDivisionScreenState extends State<SelectDivisionScreen> {
  // Use List<DivisionModel> NOT List<Map<String, dynamic>>
  List<DivisionModel> divisions = [];

  @override
  void initState() {
    super.initState();
    fetchDivisions();
  }

  Future<void> fetchDivisions() async {
    final dbHelper = LocalDBHelper(); // Create instance of DB helper
    final data = await dbHelper.getAllDivisions(); // Returns List<DivisionModel>
    setState(() {
      divisions = data;
    });
  }

  void navigateToAttendance(String divisionId, String divisionName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(
          divisionId: divisionId,
          divisionName: divisionName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Division"),
        backgroundColor: Colors.indigo,
      ),
      body: divisions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: divisions.length,
        itemBuilder: (context, index) {
          final division = divisions[index];
          return GestureDetector(
            onTap: () => navigateToAttendance(division.id, division.name),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.class_, color: Colors.indigo),
                title: Text(
                  division.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing:
                const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}
