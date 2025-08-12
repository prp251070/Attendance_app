import 'dart:io';
import '../assets/template.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/student_model.dart';
import '../../utils/helpers.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';
import '../services/local_db_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/image_helper.dart';



class AddStudentScreen extends StatefulWidget {
  final String divisionId;
  final String divisionName;
  final Map<String, dynamic>? studentToEdit; // or use your Student model if available

  const AddStudentScreen({
    super.key,
    required this.divisionId,
    required this.divisionName,
    this.studentToEdit,
  });

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}


class _AddStudentScreenState extends State<AddStudentScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.studentToEdit != null) {
      final student = widget.studentToEdit!;
      _nameController.text = student['name'] ?? '';
      _addressController.text = student['address'] ?? '';
      _contactController.text = student['contact'] ?? '';
      _parentContactController.text = student['parent_contact'] ?? '';
      _emailController.text = student['email'] ?? '';
      _bloodGroupController.text = student['blood_group'] ?? '';
      _dobController.text = student['date_of_birth'] != null
          ? student['date_of_birth'].toString().split('T')[0]
          : '';
    }
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _parentContactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;

  Future<File?> compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(      file.absolute.path,
      targetPath,
      quality: 60, // Reduce image size (0-100)
    );

    return compressedXFile != null ? File(compressedXFile.path) : null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File originalFile = File(pickedFile.path);
      File? compressedFile = await compressImage(originalFile); // Compress the image

      if (compressedFile != null) {
        setState(() {
          _imageFile = compressedFile; // Use the compressed image
        });
      } else {
        // Fallback to original if compression failed
        setState(() {
          _imageFile = originalFile;
        });
      }
    }
  }




  // Future<void> _uploadImageToSupabase(String studentId) async {
  //   if (_imageFile == null) return;
  //   final storage = Supabase.instance.client.storage;
  //   final path = 'student-photos/$studentId.jpg';
  //   await storage.from('student-photos').upload(path, _imageFile!);
  //   final publicUrl = storage.from('student-photos').getPublicUrl(path);
  //   setState(() {
  //     _ImageUrl = publicUrl;
  //   });
  // }

  // void _parseExcel(File file) async {
  //   final bytes = await file.readAsBytes();
  //   final excel = Excel.decodeBytes(bytes);
  //   final sheet = excel.tables[excel.tables.keys.first];
  //   if (sheet == null) return;
  //
  //   for (var row in sheet.rows.skip(1)) {
  //     final name = toTitleCase(row[0]?.value.toString() ?? '');
  //     final roll = int.tryParse(row[1]?.value.toString() ?? '0') ?? 0;
  //     final dob = row[2]?.value;
  //     // Continue for other fields...
  //     // Then insert into Supabase
  //   }
  // }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    try {
    final supabase = Supabase.instance.client;
    //final id = supabase.auth.currentUser!.id + DateTime.now().millisecondsSinceEpoch.toString();
    final id = const Uuid().v4();

    final name = capitalizeWords(_nameController.text.trim());
    final newStudentId = id;

    // Step 1: Fetch existing students from this division
    final existingResponse = await supabase
        .from('students')
        .select('id, name, division_id')
        .eq('division_id', widget.divisionId);

    if (existingResponse == null || existingResponse is! List) {
      debugPrint('Failed to fetch existing students');
      return;
    }

// Step 2: Create combined list with new student
    final List<Map<String, dynamic>> allStudents = [
      ...existingResponse.map<Map<String, dynamic>>((e) =>
      {
        'id': e['id'],
        'name': e['name'],
        'division_id': e['division_id'],
      }),
      {
        'id': newStudentId,
        'name': name,
        'division_id': widget.divisionId,
      },
    ];
// Step 3: Sort alphabetically
    allStudents.sort((a, b) =>
        a['name'].toString().compareTo(b['name'].toString()));

// Step 4: Assign roll numbers
    for (int i = 0; i < allStudents.length; i++) {
      allStudents[i]['roll_number'] = i + 1;
    }
// Step 5: Update roll numbers of existing students in Supabase
    for (final student in allStudents) {
      // Only update if not the new student
      if (student['id'] != newStudentId) {
        await supabase.from('students').update({
          'roll_number': student['roll_number'],
        }).eq('id', student['id'].toString());
      }
    }
// Step 5: Find new roll number for the current student
    final newEntry = allStudents.firstWhere((e) => e['id'] == newStudentId);
    //final rollNumber = newEntry['roll_number'];
    final rollNumber = int.parse(newEntry['roll_number'].toString());


    String? imageUrl;
    if (_imageFile != null) {
      // ✅ Compress the image before upload
      File? compressedImage = await compressImage(_imageFile!);

      if (compressedImage != null) {
        final imageBytes = await compressedImage.readAsBytes();
        final path = '$id.jpg';

        await supabase.storage
            .from('student-photos')
            .uploadBinary(path, imageBytes, fileOptions: const FileOptions(upsert: true));

        imageUrl = supabase.storage.from('student-photos').getPublicUrl(path);
        final cachedFile = await downloadAndCacheImage(imageUrl, '$id.jpg');
        final localImagePath = cachedFile?.path;
      }
    }
    String? localImagePath;
    if (_imageFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/students_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final fileName = '$id.jpg';
      final filePath = '${imageDir.path}/$fileName';
      final savedImage = await File(_imageFile!.path).copy(filePath);
      localImagePath = savedImage.path;
    }
    final dob = DateTime.tryParse(_dobController.text.trim());
    final db = await LocalDBHelper.instance.database;

    // Add this near the top of your _addStudent() function, before insertion
    final alreadyExists = await LocalDBHelper.instance.studentExists(
      _emailController.text.trim(),
      _nameController.text.trim(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Student with same email or name already exists.')),
      );
      return; // Stop here, don’t add duplicate
    }

    await db.insert('students', {
      'id': id,
      'name': name,
      'roll_number': rollNumber,
      'blood_group': _bloodGroupController.text.trim(),
      'date_of_birth': dob?.toIso8601String(),
      'photo_url': imageUrl,
      'division_id': widget.divisionId,
      'address': _addressController.text.trim(),
      'contact': _contactController.text.trim(),
      'parent_contact': _parentContactController.text.trim(),
      'email': _emailController.text.trim(),
      'photo_local_path': localImagePath,
      'is_synced': 0,
    });

    await supabase.from('students').insert({
      'id': id.toString(), // String or UUID
      'name': name, // String
      'roll_number': int.parse(rollNumber.toString()), // Ensure it's int
      'blood_group': _bloodGroupController.text.trim(), // String
      'date_of_birth': dob?.toIso8601String(), // String? (ISO date)
      'photo_url': imageUrl, // String? (nullable)
      'division_id': widget.divisionId.toString(), // String
      'address': _addressController.text.trim(), // String
      'contact': _contactController.text.trim(), // String
      'parent_contact': _parentContactController.text.trim(), // String
      'email': _emailController.text.trim(), // String
    });

    if (mounted) {
      Navigator.pop(context);
    }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String capitalizeWords(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }


  Future<void> _uploadExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) return;

      final fileBytes = result.files.single.bytes;
      if (fileBytes == null) {
        debugPrint('File bytes are null');
        return;
      }

      final excel = Excel.decodeBytes(fileBytes);
      final Sheet? sheet = excel['Sheet1'];
      if (sheet == null) {
        debugPrint('Sheet1 not found');
        return;
      }

      final supabase = Supabase.instance.client;
      final db = await LocalDBHelper.instance.database;

      /// 1. Fetch existing students in that division
      final existing = await db.query(
        'students',
        where: 'division_id = ?',
        whereArgs: [widget.divisionId],
      );

      /// 2. Parse Excel and prepare new students
      List<Map<String, dynamic>> allStudents = [
        ...existing.map((e) =>
        {
          'id': e['id'],
          'name': e['name'],
          'division_id': widget.divisionId,
        }),
      ];

      List<Map<String, dynamic>> toInsert = [];

      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);

        final nameRaw = row[0]?.value.toString().trim() ?? '';
        if (nameRaw.isEmpty) continue;

        final name = capitalizeWords(nameRaw);
        final dob = row[1]?.value.toString().trim();
        final bloodGroup = row[2]?.value.toString().trim();
        final address = row[3]?.value.toString().trim();
        final contact = row[4]?.value.toString().trim();
        final parentContact = row[5]?.value.toString().trim();
        final email = row[6]?.value.toString().trim();

        // Avoid duplicate email or name in SQLite


        final newId = const Uuid().v4();

        allStudents.add({
          'id': newId,
          'name': name,
          'division_id': widget.divisionId,
        });

        toInsert.add({
          'id': newId,
          'name': name,
          'date_of_birth': dob,
          'blood_group': bloodGroup,
          'address': address,
          'contact': contact,
          'parent_contact': parentContact,
          'email': email,
        });
      }

      // Sort all students alphabetically and assign roll numbers
      allStudents.sort((a, b) =>
          a['name'].toString().compareTo(b['name'].toString()));
      for (int i = 0; i < allStudents.length; i++) {
        allStudents[i]['roll_number'] = i + 1;
      }

      // Update local SQLite and Supabase
      for (final student in toInsert) {
        final studentId = student['id'];
        final rollNumber = allStudents.firstWhere((s) =>
        s['id'] == studentId)['roll_number'];

        // Insert into SQLite
        await db.insert('students', {
          'id': student['id'],
          'name': student['name'],
          'roll_number': rollNumber,
          'blood_group': student['blood_group'],
          'date_of_birth': student['date_of_birth'],
          'photo_url': null,
          'division_id': widget.divisionId,
          'address': student['address'],
          'contact': student['contact'],
          'parent_contact': student['parent_contact'],
          'email': student['email'],
          'is_synced': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Sync to Supabase
        await supabase.from('students').insert({
          'id': studentId,
          'name': student['name'],
          'roll_number': rollNumber,
          'blood_group': student['blood_group'],
          'date_of_birth': student['date_of_birth'],
          'photo_url': null,
          'division_id': widget.divisionId,
          'address': student['address'],
          'contact': student['contact'],
          'parent_contact': student['parent_contact'],
          'email': student['email'],
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel data uploaded successfully.')),
        );
        Navigator.pop(context);
      }
    }
    catch (e) {
      debugPrint('Excel upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading Excel: $e')),
      );
    }
  }


  Future<void> _updateStudent() async {
    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final db = await LocalDBHelper.instance.database;

      final id = widget.studentToEdit!['id'];
      final dob = DateTime.tryParse(_dobController.text.trim());

      String? imageUrl = widget.studentToEdit!['photo_url'];

      // ✅ 1. Upload image if selected
      if (_imageFile != null) {
        File? compressedImage = await compressImage(_imageFile!);
        if (compressedImage != null) {
          final imageBytes = await compressedImage.readAsBytes();
          final path = '$id.jpg';

          await supabase.storage
              .from('student-photos')
              .uploadBinary(path, imageBytes, fileOptions: const FileOptions(upsert: true));

          imageUrl = supabase.storage.from('student-photos').getPublicUrl(path);
        }
      }

      // ✅ 2. Prepare updated data
      final updatedStudent = {
        'name': capitalizeWords(_nameController.text.trim()),
        'address': _addressController.text.trim(),
        'contact': _contactController.text.trim(),
        'parent_contact': _parentContactController.text.trim(),
        'email': _emailController.text.trim(),
        'blood_group': _bloodGroupController.text.trim(),
        'date_of_birth': dob?.toIso8601String(),
        'photo_url': imageUrl,
        'is_synced': 1,
      };

      // ✅ 3. Update Supabase
      final supabaseResp = await supabase
          .from('students')
          .update(updatedStudent)
          .eq('id', id)
          .select(); // 🔑 Needed to actually execute the update

      if (supabaseResp.isEmpty) {
        throw 'Update failed: no data returned from Supabase.';
      }

      // ✅ 4. Update local SQLite
      await db.update(
        'students',
        updatedStudent,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update student: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }

  }




  @override
  @override
  Widget build(BuildContext context) {
    final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        title: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Student Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : widget.studentToEdit?['photo_url'] != null
                              ? NetworkImage(widget.studentToEdit!['photo_url']) as ImageProvider
                              : null,
                          child: _imageFile == null && (widget.studentToEdit?['photo_url'] == null)
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, size: 18, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person, validator: 'Enter name'),
                  _buildTextField(controller: _dobController, label: 'Date of Birth (YYYY-MM-DD)', icon: Icons.cake, readOnly: true, onTap: () async {
                    FocusScope.of(context).unfocus();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1995),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  }),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _bloodGroupController.text.isNotEmpty ? _bloodGroupController.text : null,
                    decoration: _buildInputDecoration('Blood Group', Icons.bloodtype),
                    items: _bloodGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
                    onChanged: (value) => _bloodGroupController.text = value ?? '',
                    validator: (value) => value == null || value.isEmpty ? 'Please select a blood group' : null,
                  ),
                  const SizedBox(height: 10),

                  _buildTextField(controller: _addressController, label: 'Address', icon: Icons.home),
                  _buildTextField(controller: _contactController, label: 'Contact Number', icon: Icons.phone, inputType: TextInputType.phone),
                  _buildTextField(controller: _parentContactController, label: "Parent's Contact Number", icon: Icons.phone_android, inputType: TextInputType.phone),
                  _buildTextField(controller: _emailController, label: 'Email ID', icon: Icons.email, inputType: TextInputType.emailAddress),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isUploading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.save),
                      label: Text(widget.studentToEdit != null ? 'Update Student' : 'Add Student'),
                      onPressed: _isUploading ? null : () {
                        if (widget.studentToEdit != null) {
                          _updateStudent();
                        } else {
                          _submit();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white, // This sets the text (and icon) color to white
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),

                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _uploadExcelFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Excel'),

                      ),
                      TextButton.icon(
                        onPressed: () => generateExcelTemplate(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Template'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
    String? validator,
    void Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        decoration: _buildInputDecoration(label, icon),
        validator: validator != null ? (val) => val == null || val.isEmpty ? validator : null : null,
        onTap: onTap,
      ),
    );
  }
}

