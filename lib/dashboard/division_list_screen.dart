import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_db_helper.dart';
import '../models/division_model.dart';
import 'student_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DivisionListScreen extends StatefulWidget {
  const DivisionListScreen({super.key});

  @override
  State<DivisionListScreen> createState() => _DivisionListScreenState();
}

class _DivisionListScreenState extends State<DivisionListScreen> {
  List<DivisionModel> _divisions = [];

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    final db = await LocalDBHelper.instance.database;
    final divisionMaps = await db.query('divisions', orderBy: 'created_at ASC');

    final divisions = divisionMaps.map((map) => DivisionModel.fromMap(map)).toList();

    setState(() {
      _divisions = divisions;
    });
  }


  Future<void> _addDivision() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {

        return AlertDialog( // ✅ Add return here
          title: const Text('Add Division'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Division name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), // Correct context
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newDivision = DivisionModel(
                    id: const Uuid().v4(),
                    name: name,
                    createdAt: DateTime.now().toIso8601String(),
                  );

                  try {
                    final supabase = Supabase.instance.client;

                    // ✅ 1. Insert into Supabase
                    final response = await supabase.from('divisions').insert({
                      'id': newDivision.id,
                      'name': newDivision.name,
                      'created_at': newDivision.createdAt,
                    }).select(); // Make sure the query executes

                    if (response.isEmpty) {
                      throw 'Failed to insert division to Supabase.';
                    }

                    // ✅ 2. Insert into SQLite only after Supabase success
                    await LocalDBHelper.instance.insertDivision(newDivision);

                    // ✅ 3. Reload UI
                    await _loadDivisions();
                    Navigator.pop(ctx); // Close dialog

                  } catch (e) {
                    debugPrint('Division sync error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add division: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showDivisionOptions(DivisionModel division) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Division'),
            onTap: () {
              Navigator.pop(context);
              _renameDivision(division);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Division'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Deletion'),
                  content: const Text('Are you sure you want to delete this division?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final supabase = Supabase.instance.client;

                  // ✅ 1. Delete from Supabase
                  final response = await supabase
                      .from('divisions')
                      .delete()
                      .eq('id', division.id);

                  if (response.error != null) {
                    throw 'Supabase deletion failed: ${response.error!.message}';
                  }

                  // ✅ 2. Delete from local SQLite
                  await LocalDBHelper.instance.deleteDivision(division.id);

                  // ✅ 3. Refresh UI
                  await _loadDivisions();

                  // ✅ 4. Close the options dialog
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('Delete error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete division: $e')),
                  );
                }
              }
            },
          ),

        ],
      ),
    );
  }
  Future<void> _deleteDivision(DivisionModel division) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete division "${division.name}" and all its students?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;

      // ✅ Delete from Supabase
      await supabase
          .from('divisions')
          .delete()
          .eq('id', division.id);

      // ✅ Delete associated students from SQLite
      await LocalDBHelper.instance.deleteStudentsByDivision(division.id);

      // ✅ Delete division from SQLite
      await LocalDBHelper.instance.deleteDivision(division.id);

      // ✅ Refresh UI
      await _loadDivisions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Division and its students deleted successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete division: $e')),
        );
      }
    }
  }




  Future<void> _renameDivision(DivisionModel division) async {
    final controller = TextEditingController(text: division.name);

    await showDialog(
      context: context,
      barrierDismissible: false, // Optional: block tap outside
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Division'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // ✅ Use ctx here
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();

              if (newName.isNotEmpty) {
                final updatedDivision = division.copyWith(name: newName);

                try {
                  final supabase = Supabase.instance.client;

                  // ✅ Update Supabase
                  final response = await supabase
                      .from('divisions')
                      .update({'name': newName})
                      .eq('id', division.id)
                      .select();

                  if (response.isEmpty) {
                    throw 'Supabase update failed or returned empty response';
                  }

                  // ✅ Update SQLite
                  await LocalDBHelper.instance.updateDivision(updatedDivision);

                  // ✅ Refresh UI
                  await _loadDivisions();

                  // ✅ Close dialog
                  Navigator.pop(ctx);
                } catch (e) {
                  debugPrint('Rename error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rename failed: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Divisions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _divisions.isEmpty
            ? const Center(
          child: Text(
            'No divisions added.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        )
            : GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: _divisions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final div = _divisions[index];

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentListScreen(
                    divisionId: div.id,
                    divisionName: div.name,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(4, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 3-dot menu
                    Positioned(
                      right: 4,
                      top: 4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 22),
                        onSelected: (value) {
                          if (value == 'rename') {
                            _renameDivision(div);
                          } else if (value == 'delete') {
                            _deleteDivision(div);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                    // Division Name
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                        child: Text(
                          div.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDivision,
        backgroundColor: const Color(0xFF37474F),
        elevation: 8,
        child: const Icon(Icons.add, size: 30),
        tooltip: 'Add Division',
      ),
    );
  }

}
