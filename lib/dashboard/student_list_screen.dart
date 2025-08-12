import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_student_screen.dart'; // Update with actual path
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import'../services/local_db_helper.dart';

class StudentListScreen extends StatefulWidget {
  final String divisionId;
  final String divisionName;

  const StudentListScreen({
    super.key,
    required this.divisionId,
    required this.divisionName,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  // Future<void> fetchStudents() async {
  //   setState(() => isLoading = true);
  //   final response = await Supabase.instance.client
  //       .from('students')
  //       .select()
  //       .eq('division_id', widget.divisionId)
  //       .order('roll_number', ascending: true);
  //   setState(() {
  //     students = List<Map<String, dynamic>>.from(response);
  //     isLoading = false;
  //   });
  // }
  Future<void> fetchStudents() async {
    setState(() => isLoading = true);

    try {
      final db = await LocalDBHelper.instance.database;

      final result = await db.query(
        'students',
        where: 'division_id = ?',
        whereArgs: [widget.divisionId],
        orderBy: 'roll_number ASC',
      );

      setState(() {
        students = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching students from SQLite: $e');
      setState(() => isLoading = false);
    }
  }


  void showStudentOptions(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStudentScreen(
                      divisionId: widget.divisionId,
                      divisionName: widget.divisionName,
                      studentToEdit: student,
                    ),
                  ),
                ).then((_) => fetchStudents());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet or menu

                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text('Are you sure you want to delete this student?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final id = student['id'];

                  // 🔁 Step 1: Delete from Supabase
                  try {
                    await Supabase.instance.client
                        .from('students')
                        .delete()
                        .eq('id', id);
                  } catch (e) {
                    debugPrint('Supabase delete failed: $e');
                  }

                  // 🔁 Step 2: Delete from SQLite
                  try {
                    final db = await LocalDBHelper().database;
                    await db.delete(
                      'students',
                      where: 'id = ?',
                      whereArgs: [id],
                    );
                  } catch (e) {
                    debugPrint('SQLite delete failed: $e');
                  }

                  // 🔁 Step 3: Refresh UI
                  fetchStudents();
                }
              },
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students - ${widget.divisionName}'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
              await LocalDBHelper.instance.syncStudentsFromSupabase();
              await fetchStudents(); // Refresh local list after sync
            },
          ),

        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddStudentScreen(
                divisionId: widget.divisionId,
                divisionName: widget.divisionName,
              ),
            ),
          ).then((_) => fetchStudents());
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchStudents,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: students.length,
          itemBuilder: (_, index) {
            final student = students[index];
            return GestureDetector(
              onLongPress: () => showStudentOptions(student),
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: student['photo_local_path'] != null && student['photo_local_path'].toString().isNotEmpty
                        ? FileImage(File(student['photo_local_path']))
                        : student['photo_url'] != null
                        ? NetworkImage(student['photo_url'])
                        : null,
                    child: (student['photo_local_path'] == null || student['photo_local_path'].toString().isEmpty) &&
                        (student['photo_url'] == null || student['photo_url'].toString().isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    student['name'],
                    style: AppTextStyles.cardTitle,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Roll No: ${student['roll_number']}'),
                      Text('DOB: ${student['date_of_birth'] ?? 'N/A'}'),
                      Text('Blood Group: ${student['blood_group'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => showStudentOptions(student),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
