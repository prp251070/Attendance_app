import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> generateExcelTemplate(BuildContext context) async {
  final Excel excel = Excel.createExcel();
  final Sheet sheet = excel['Sheet1'];

  sheet.appendRow([
    TextCellValue('name'),
    TextCellValue('date_of_birth'),
    TextCellValue('blood_group'),
    TextCellValue('address'),
    TextCellValue('contact'),
    TextCellValue('parents_contact_number'),
    TextCellValue('email'),
  ]);

  for (int i = 1; i <= 2; i++) {
    sheet.appendRow([
      TextCellValue('Student $i'),
      TextCellValue('2010-01-01'),
      TextCellValue('O+'),
      TextCellValue('City $i'),
      TextCellValue('999999999$i'),
      TextCellValue('888888888$i'),
      TextCellValue('student$i@email.com'),
    ]);
  }

  final List<int> fileBytes = excel.save()!;
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/student_template.xlsx';
  final file = File(filePath);
  await file.writeAsBytes(fileBytes);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Template downloaded to: $filePath')),
  );

  await OpenFile.open(filePath);
}
