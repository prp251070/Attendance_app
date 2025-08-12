import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/division_model.dart';
import '../../services/local_db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceArchiveViewer extends StatefulWidget {
  const AttendanceArchiveViewer({super.key});

  @override
  State<AttendanceArchiveViewer> createState() => _AttendanceArchiveViewerState();
}

class _AttendanceArchiveViewerState extends State<AttendanceArchiveViewer> {
  final SupabaseClient supabase = Supabase.instance.client;

  DivisionModel? selectedDivision;
  List<DivisionModel> divisions = [];

  List<Map<String, dynamic>> attendanceData = [];
  List<Map<String, dynamic>> filteredData = [];

  bool isLoading = false;
  bool fetchByMonth = true;

  DateTime selectedDate = DateTime.now();
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  String searchQuery = '';
  String sortOption = 'Roll Number';
  final List<String> sortOptions = ['Roll Number', 'Date'];

  @override
  void initState() {
    super.initState();
    _loadDivisionsFromLocalDB();
  }

  Future<void> _loadDivisionsFromLocalDB() async {
    final result = await LocalDBHelper.instance.getAllDivisions();
    setState(() {
      divisions = result;
      if (divisions.isNotEmpty && selectedDivision == null) {
        selectedDivision = divisions.first;
      }
    });
  }

  Future<void> fetchAttendanceFiles() async {
    if (selectedDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a division.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      attendanceData = [];
      filteredData = [];
    });

    try {
      final folderItems = await supabase.storage
          .from('attendance-archives')
          .list(path: '');

      final divisionPrefix = selectedDivision!.name.replaceAll(" ", "_");
      final List<String> fileNames = [];

      if (fetchByMonth) {
        final monthPrefix = '${divisionPrefix}_${selectedYear.toString().padLeft(4, '0')}_${selectedMonth.toString().padLeft(2, '0')}';
        fileNames.addAll(folderItems
            .where((file) => file.name.startsWith(monthPrefix) && file.name.endsWith('.json'))
            .map((file) => file.name));
      } else {
        final dateStr = DateFormat('yyyy_MM_dd').format(selectedDate);
        final fileName = '${divisionPrefix}_$dateStr.json';
        if (folderItems.any((f) => f.name == fileName)) {
          fileNames.add(fileName);
        }
      }

      List<Map<String, dynamic>> mergedData = [];
      for (final fileName in fileNames) {
        final fileData = await supabase.storage
            .from('attendance-archives')
            .download(fileName);
        final decoded = utf8.decode(fileData);
        final List<dynamic> rawList = jsonDecode(decoded);
        final List<Map<String, dynamic>> parsedList =
        List<Map<String, dynamic>>.from(rawList);
        mergedData.addAll(parsedList);
      }

      mergedData.sort((a, b) {
        final rollCompare = (a['roll_number'] ?? 0).compareTo(b['roll_number'] ?? 0);
        if (rollCompare != 0) return rollCompare;
        return a['date'].compareTo(b['date']);
      });

      setState(() {
        attendanceData = mergedData;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(attendanceData);

    if (searchQuery.trim().isNotEmpty) {
      temp = temp
          .where((entry) => entry['student_name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (sortOption == 'Roll Number') {
      temp.sort((a, b) =>
          (a['roll_number'] ?? 0).compareTo(b['roll_number'] ?? 0));
    } else if (sortOption == 'Date') {
      temp.sort((a, b) => a['date'].compareTo(b['date']));
    }

    setState(() => filteredData = temp);
  }
  Future<void> generatePdfAndDownload() async {
    final pdf = pw.Document();
    final divisionName = selectedDivision?.name ?? 'Unknown Division';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'Attendance Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Class: $divisionName'),
          pw.Text(fetchByMonth
              ? 'Month: ${DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth))}'
              : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Roll Number', 'Student Name', 'Date', 'Present'],
            data: filteredData.map((entry) {
              return [
                entry['roll_number'].toString(),
                entry['student_name'],
                entry['date'],
                (entry['is_present'] == true || entry['is_present'] == 1) ? 'Yes' : 'No',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 10),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );


    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Past Attendance"),
          actions: [
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: filteredData.isEmpty
                  ? null
                  : () async {
                await generatePdfAndDownload();
              },
            ),
          ],
        ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Division & Toggle Selector
            Row(
              children: [
                Expanded(
                  child: DropdownButton<DivisionModel>(
                    isExpanded: true,
                    value: selectedDivision,
                    hint: const Text("Select Division"),
                    items: divisions.map((division) {
                      return DropdownMenuItem(
                        value: division,
                        child: Text(division.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedDivision = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ToggleButtons(
                  isSelected: [!fetchByMonth, fetchByMonth],
                  onPressed: (index) {
                    setState(() => fetchByMonth = index == 1);
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Pick by Date"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Pick by Month"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Picker UI
            if (fetchByMonth)
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedMonth,
                      isExpanded: true,
                      items: List.generate(12, (i) => i + 1).map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(DateFormat.MMMM().format(DateTime(0, month))),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedMonth = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      isExpanded: true,
                      items: List.generate(5, (i) => 2023 + i).map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedYear = val!),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Search, Sort, Fetch
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search student name",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      searchQuery = val;
                      applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: sortOption,
                  items: sortOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    sortOption = val!;
                    applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: fetchAttendanceFiles,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Fetch"),
                ),
              ],
            ),
            const Divider(),

            // Attendance List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredData.isEmpty
                  ? const Center(child: Text("No attendance records found."))
                  : ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final entry = filteredData[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                          "${entry['student_name']} (${entry['roll_number']})"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date: ${entry['date']}"),
                          Text(
                              "Present: ${(entry['is_present'] == true || entry['is_present'] == 1) ? 'Yes' : 'No'}"),
                          if ((entry['reason'] ?? '').toString().isNotEmpty)
                            Text("Reason: ${entry['reason']}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
