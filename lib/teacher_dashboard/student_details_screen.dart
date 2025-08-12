import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StudentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student['name'] ?? 'Student Details'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile photo section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: student['photo_url'] != null &&
                          student['photo_url'].isNotEmpty
                          ? Image.network(
                        student['photo_url'],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 100),
                      )
                          : const Icon(Icons.person, size: 100),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll No: ${student['roll_number']}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      'Division: ${student['division_name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Detail tiles
            _buildDetailCard('Date of Birth', student['date_of_birth']),
            _buildDetailCard('Blood Group', student['blood_group']),
            _buildDetailCard('Address', student['address']),
            _buildDetailCard('Contact', student['contact']),
            _buildDetailCard('Parent Contact', student['parent_contact']),
            _buildDetailCard('Email', student['email']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String? value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.label_important, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value?.isNotEmpty == true ? value! : 'Not available'),
      ),
    );
  }
}
