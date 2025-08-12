import 'package:flutter/material.dart';
import '../../models/division_model.dart';
import '../../services/local_db_helper.dart';
import 'select_date_screen.dart';

class DivisionAttendanceListScreen extends StatefulWidget {
  const DivisionAttendanceListScreen({super.key});

  @override
  State<DivisionAttendanceListScreen> createState() => _DivisionAttendanceListScreenState();
}

class _DivisionAttendanceListScreenState extends State<DivisionAttendanceListScreen> {
  List<DivisionModel> divisions = [];

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    final result = await LocalDBHelper.instance.getAllDivisions();
    setState(() => divisions = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Division")),
      body: ListView.builder(
        itemCount: divisions.length,
        itemBuilder: (context, index) {
          final division = divisions[index];
          return Card(
            child: ListTile(
              title: Text(division.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectDateScreen(divisionId: division.id, divisionName: division.name),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
// TODO Implement this library.