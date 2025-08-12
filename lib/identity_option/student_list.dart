// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import '../constants/app_colors.dart';
// import '../services/local_db_helper.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:printing/printing.dart';
//
// class StudentListScreen extends StatelessWidget {
//   const StudentListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Student List'),
//         backgroundColor: AppColors.primary,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: () async {
//               final action = await showMenu(
//                 context: context,
//                 position: const RelativeRect.fromLTRB(100, 100, 100, 100),
//                 items: const [
//                   PopupMenuItem(
//                     value: 'show_identity_cards',
//                     child: Text("Show Identity Cards in Bulk"),
//                   ),
//                 ],
//               );
//               if (action == 'show_identity_cards') {
//                 _generateBulkIdentityCards(context);
//               }
//             },
//           ),
//         ],
//       ),
//       body: FutureBuilder(
//         future: _loadStudents(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           final students = List<Map<String, dynamic>>.from(snapshot.data!);
//           students.sort((a, b) => a['roll_number'].compareTo(b['roll_number']));
//
//           // Group by division_name
//           final Map<String, List<Map<String, dynamic>>> grouped = {};
//           for (var student in students) {
//             final divisionName = student['division_name'] ?? 'Unknown Division';
//             grouped.putIfAbsent(divisionName, () => []).add(student);
//           }
//
//           return ListView(
//             padding: const EdgeInsets.all(12),
//             children: grouped.entries.map((entry) {
//               final divisionName = entry.key;
//               final divisionStudents = entry.value;
//
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//                     child: Text(
//                       divisionName,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blueGrey,
//                       ),
//                     ),
//                   ),
//                   ...divisionStudents.map((student) => Card(
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     elevation: 4,
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: ListTile(
//                       leading: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: student['photo_url'] != null && student['photo_url'].isNotEmpty
//                             ? Image.network(
//                           student['photo_url'],
//                           width: 50,
//                           height: 50,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) =>
//                           const Icon(Icons.image_not_supported),
//                         )
//                             : const Icon(Icons.person, size: 40),
//                       ),
//                       title: Text(
//                         student['name'] ?? 'No Name',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         'DOB: ${student['date_of_birth'] ?? 'Unknown'}',
//                         style: TextStyle(color: AppColors.textLight),
//                       ),
//                       trailing: Text(
//                         'Roll: ${student['roll_number']}',
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   )),
//                 ],
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
//
//   Future<List<Map<String, dynamic>>> _loadStudents() async {
//     final db = await LocalDBHelper.instance.database;
//     return await db.rawQuery('''
//       SELECT students.*, divisions.name AS division_name
//       FROM students
//       LEFT JOIN divisions ON students.division_id = divisions.id
//     ''');
//   }
//
//   Future<pw.ImageProvider> _getStudentImage(String? url) async {
//     if (url == null || url.isEmpty) {
//       return pw.MemoryImage((await rootBundle.load('lib/assets/placeholder.png')).buffer.asUint8List());
//     }
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         return pw.MemoryImage(response.bodyBytes);
//       }
//     } catch (_) {}
//
//     return pw.MemoryImage((await rootBundle.load('lib/assets/placeholder.png')).buffer.asUint8List());
//   }
//
//   Future<void> _generateBulkIdentityCards(BuildContext context) async {
//     final students = await _loadStudents();
//     final pdf = pw.Document();
//
//     for (int i = 0; i < students.length; i += 6) {
//       final cards = <pw.Widget>[];
//
//       for (int j = 0; j < 6; j++) {
//         if (i + j < students.length) {
//           final student = students[i + j];
//           final studentImage = await _getStudentImage(student['photo_url']);
//           final logo = pw.MemoryImage((await rootBundle.load('lib/assets/school_logo.png')).buffer.asUint8List());
//
//           final card = pw.Container(
//             width: 180,
//             height: 100,
//             padding: const pw.EdgeInsets.all(4),
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Row(
//                   children: [
//                     pw.Image(logo, width: 20, height: 20),
//                     pw.SizedBox(width: 5),
//                     pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text('School Name', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
//                         pw.Text('School Address', style: pw.TextStyle(fontSize: 8)),
//                       ],
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 4),
//                 pw.Row(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Container(
//                       width: 40,
//                       height: 50,
//                       decoration: pw.BoxDecoration(border: pw.Border.all()),
//                       child: pw.Image(studentImage, fit: pw.BoxFit.cover),
//                     ),
//                     pw.SizedBox(width: 4),
//                     pw.Expanded(
//                       child: pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           pw.Text('Name: ${student['name']}', style: pw.TextStyle(fontSize: 8)),
//                           pw.Text('DOB: ${student['date_of_birth'] ?? '-'}', style: pw.TextStyle(fontSize: 8)),
//                           pw.Text('Blood: ${student['blood_group'] ?? '-'}', style: pw.TextStyle(fontSize: 8)),
//                           pw.Text('Contact: ${student['contact'] ?? '-'}', style: pw.TextStyle(fontSize: 8)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 4),
//                 pw.Text('Address: ${student['address'] ?? '-'}', style: pw.TextStyle(fontSize: 7)),
//                 pw.SizedBox(height: 2),
//                 pw.Align(
//                   alignment: pw.Alignment.centerRight,
//                   child: pw.Column(
//                     children: [
//                       pw.Text('Principal\'s Sign', style: pw.TextStyle(fontSize: 7)),
//                       pw.Container(height: 1, color: PdfColors.black, width: 40),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           );
//
//           cards.add(card);
//         }
//       }
//
//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(12),
//           build: (context) => pw.Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: cards,
//           ),
//         ),
//       );
//     }
//
//     final output = await getTemporaryDirectory();
//     final file = File('${output.path}/identity_cards.pdf');
//     await file.writeAsBytes(await pdf.save());
//
//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }
// }
// Add this import
import 'dart:ui' as pw;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../constants/app_colors.dart';
import '../services/local_db_helper.dart';
import '../teacher_dashboard/student_details_screen.dart';

class StudentListScreen extends StatefulWidget {
  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> allStudents = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = await LocalDBHelper.instance.database;
    final result = await db.rawQuery('''
    SELECT students.*, divisions.name AS division_name 
    FROM students
    LEFT JOIN divisions ON students.division_id = divisions.id
    ORDER BY division_name ASC, roll_number ASC
  ''');

    setState(() {
      allStudents = result;
    });
  }

  List<Map<String, dynamic>> _filteredStudents() {
    if (_searchQuery.isEmpty) return allStudents;
    return allStudents.where((student) {
      final name = student['name']?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupStudentsByDivision() {
    final students = _filteredStudents();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var student in students) {
      final divisionName = student['division_name'] ?? 'Unknown Division';
      grouped.putIfAbsent(divisionName, () => []).add(student);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupStudentsByDivision();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student List'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              final action = await showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 100, 100, 100),
                items: const [
                  PopupMenuItem(
                    value: 'show_identity_cards',
                    child: Text("Show Identity Cards in Bulk"),
                  ),
                ],
              );
              if (action == 'show_identity_cards') {
                _generateBulkIdentityCards(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView(
              padding: const EdgeInsets.all(12),
              children: grouped.entries.map((entry) {
                final divisionName = entry.key;
                final students = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(
                        divisionName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    ...students.map((student) => Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailsScreen(student: student),
                            ),
                          );
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: student['photo_url'] != null && student['photo_url'].isNotEmpty
                              ? Image.network(
                            student['photo_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                          )
                              : const Icon(Icons.person, size: 40),
                        ),
                        title: Text(
                          student['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'DOB: ${student['date_of_birth'] ?? 'Unknown'}',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                        trailing: Text(
                          'Roll: ${student['roll_number']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.ImageProvider> _getStudentImage(String? url) async {
    if (url == null || url.isEmpty) {
      return pw.MemoryImage((await rootBundle.load('lib/assets/placeholder.png')).buffer.asUint8List());
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {}

    return pw.MemoryImage((await rootBundle.load('lib/assets/placeholder.png')).buffer.asUint8List());
  }

  Future<void> _generateBulkIdentityCards(BuildContext context) async {
    final students = _filteredStudents();
    final pdf = pw.Document();

    for (int i = 0; i < students.length; i += 8) {
      final cards = <pw.Widget>[];

      for (int j = 0; j < 8 && i + j < students.length; j++) {
        final student = students[i + j];
        final studentImage = await _getStudentImage(student['photo_url']);

        final card = pw.Container(
          width: 210,
          height: 130,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Image(
                    pw.MemoryImage((await rootBundle.load('lib/assets/school_logo.png')).buffer.asUint8List()),
                    width: 20,
                    height: 20,
                  ),
                  pw.SizedBox(width: 5),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Sayyadhari's Pratisthan", style: pw.TextStyle(fontSize: 6,color: PdfColors.red,  fontWeight: pw.FontWeight.bold),),
                      pw.Text('Mini Miracle Pre School', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(' Atharv Park Society, Sector No. 30, Nigdi, Pimpri-Chinchwad,\n Maharashtra 411035', style: pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 40,
                    height: 50,
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Image(studentImage, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Name: ${student['name']}', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('DOB: ${student['date_of_birth']}', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('Blood: ${student['blood_group']}', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('Contact: ${student['contact']}', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Address: ${student['address']}', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  children: [
                    pw.Text('Principal\'s Sign', style: pw.TextStyle(fontSize: 7)),
                    pw.Container(height: 1, color: PdfColors.black, width: 40),
                  ],
                ),
              )
            ],
          ),
        );

        cards.add(card);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cards,
            );
          },
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/identity_cards.pdf');
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
