import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/profile.dart';

// Conditional imports for web/mobile compatibility
import 'csv_util_web.dart' if (dart.library.io) 'csv_util_mobile.dart' as download_util;

class CsvUtil {
  /// Generate CSV data for a single student
  static String generateStudentCsv(Map<String, dynamic> studentWithProfile) {
    final headers = [
      'Enrollment No',
      'Full Name',
      'Class',
      'Gender',
      'Date of Birth',
      'Aadhaar',
      'Address',
      'Guardian Name',
      'Mother Name',
      'Father Name',
      'Has Siblings',
      'Community',
      '10th Percentage',
      '12th Percentage',
      'Father Income',
      'Mother Income',
      'Created At',
      'Updated At',
    ];

    // Extract profile data
    final profiles = studentWithProfile['profiles'] as Map<String, dynamic>?;
    
    final data = [
      profiles?['enrollment_no']?.toString() ?? '',
      profiles?['full_name']?.toString() ?? '',
      studentWithProfile['class']?.toString() ?? '',
      studentWithProfile['gender']?.toString() ?? '',
      studentWithProfile['dob']?.toString() ?? '',
      studentWithProfile['aadhaar']?.toString() ?? '',
      studentWithProfile['address']?.toString() ?? '',
      studentWithProfile['guardian_name']?.toString() ?? '',
      studentWithProfile['mother_name']?.toString() ?? '',
      studentWithProfile['father_name']?.toString() ?? '',
      (studentWithProfile['siblings'] == true) ? 'Yes' : 'No',
      studentWithProfile['community']?.toString() ?? '',
      studentWithProfile['tenth_percent']?.toString() ?? '',
      studentWithProfile['twelfth_percent']?.toString() ?? '',
      studentWithProfile['father_income']?.toString() ?? '',
      studentWithProfile['mother_income']?.toString() ?? '',
      studentWithProfile['created_at']?.toString() ?? '',
      studentWithProfile['updated_at']?.toString() ?? '',
    ];

    final csvData = [headers, data];
    return const ListToCsvConverter().convert(csvData);
  }

  /// Generate CSV data for multiple students (class export)
  static String generateClassCsv(List<Map<String, dynamic>> studentsWithProfiles) {
    final headers = [
      'Enrollment No',
      'Full Name',
      'Class',
      'Gender',
      'Date of Birth',
      'Aadhaar',
      'Address',
      'Guardian Name',
      'Mother Name',
      'Father Name',
      'Has Siblings',
      'Community',
      '10th Percentage',
      '12th Percentage',
      'Father Income',
      'Mother Income',
      'Created At',
      'Updated At',
    ];

    final csvData = [headers];

    for (final item in studentsWithProfiles) {
      try {
        // Extract profile data
        final profiles = item['profiles'] as Map<String, dynamic>?;
        if (profiles == null) continue;

        // Extract student data directly from the item
        final data = [
          profiles['enrollment_no']?.toString() ?? '',
          profiles['full_name']?.toString() ?? '',
          item['class']?.toString() ?? '',
          item['gender']?.toString() ?? '',
          item['dob']?.toString() ?? '',
          item['aadhaar']?.toString() ?? '',
          item['address']?.toString() ?? '',
          item['guardian_name']?.toString() ?? '',
          item['mother_name']?.toString() ?? '',
          item['father_name']?.toString() ?? '',
          (item['siblings'] == true) ? 'Yes' : 'No',
          item['community']?.toString() ?? '',
          item['tenth_percent']?.toString() ?? '',
          item['twelfth_percent']?.toString() ?? '',
          item['father_income']?.toString() ?? '',
          item['mother_income']?.toString() ?? '',
          item['created_at']?.toString() ?? '',
          item['updated_at']?.toString() ?? '',
        ];

        csvData.add(data);
      } catch (e) {
        // Skip this student if there's an error parsing their data
        print('Error processing student data: $e');
        continue;
      }
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Download CSV file (platform-specific implementation)
  static Future<void> downloadCsv(String csvData, String fileName) async {
    await download_util.downloadCsv(csvData, fileName);
  }

  /// Generate file name for CSV export
  static String generateFileName(String prefix, {String? className}) {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    if (className != null) {
      return '${prefix}_${className}_$timestamp.csv';
    }
    return '${prefix}_$timestamp.csv';
  }

  /// Generate CSV for multiple students
  static String generateStudentsCsv(List<Map<String, dynamic>> studentsWithProfiles) {
    return generateClassCsv(studentsWithProfiles);
  }

  /// Generate CSV for a single student using Student and Profile objects
  static String generateStudentCsvFromObjects(Student student, Profile profile) {
    final headers = [
      'Enrollment No',
      'Full Name',
      'Class',
      'Gender',
      'Date of Birth',
      'Aadhaar',
      'Address',
      'Guardian Name',
      'Mother Name',
      'Father Name',
      'Has Siblings',
      'Community',
      '10th Percentage',
      '12th Percentage',
      'Father Income',
      'Mother Income',
      'Created At',
      'Updated At',
    ];

    final data = [
      profile.enrollmentNo,
      profile.fullName,
      student.studentClass?.value ?? '',
      student.gender?.value ?? '',
      student.dob?.toString() ?? '',
      student.aadhaar ?? '',
      student.address ?? '',
      student.guardianName ?? '',
      student.motherName ?? '',
      student.fatherName ?? '',
      student.siblings ? 'Yes' : 'No',
      student.community ?? '',
      student.tenthPercent?.toString() ?? '',
      student.twelfthPercent?.toString() ?? '',
      student.fatherIncome?.toString() ?? '',
      student.motherIncome?.toString() ?? '',
      student.createdAt?.toIso8601String() ?? '',
      student.updatedAt?.toIso8601String() ?? '',
    ];

    final csvData = [headers, data];
    return const ListToCsvConverter().convert(csvData);
  }
}