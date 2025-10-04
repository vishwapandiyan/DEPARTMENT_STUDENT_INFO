import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/document.dart';
import '../constants/enums.dart';

class StudentController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create or update student record
  Future<Student> saveStudent(Student student) async {
    try {
      print('StudentController.saveStudent called');
      print('Student ID: ${student.id}');
      print('Profile ID: ${student.profileId}');
      
      final studentData = student.toJson();
      studentData['updated_at'] = DateTime.now().toIso8601String();
      
      print('Student data: $studentData');

      print('Calling Supabase upsert...');
      final response = await _supabase
          .from('students')
          .upsert(studentData)
          .select()
          .single();

      print('Upsert successful, response: $response');
      return Student.fromJson(response);
    } catch (e) {
      print('Error in StudentController.saveStudent: $e');
      rethrow;
    }
  }

  /// Get student by profile ID
  Future<Student?> getStudentByProfileId(String profileId) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) return null;
      return Student.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('id', studentId)
          .maybeSingle();

      if (response == null) return null;
      return Student.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all students with profile information
  Future<List<Map<String, dynamic>>> getAllStudentsWithProfiles({
    StudentClass? studentClass,
    StudentGender? gender,
    String? enrollmentNo,
    int? limit,
    int? offset,
  }) async {
    try {
      print('StudentController.getAllStudentsWithProfiles: Starting query with filters:');
      print('- studentClass: $studentClass');
      print('- gender: $gender');
      print('- enrollmentNo: $enrollmentNo');
      
      var query = _supabase
          .from('students')
          .select('''
            *,
            profiles!inner(
              id,
              full_name,
              enrollment_no,
              is_staff,
              class,
              profile_photo_path
            )
          ''');

      // Apply filters
      if (studentClass != null) {
        query = query.eq('class', studentClass.value);
      }

      if (gender != null) {
        query = query.eq('gender', gender.value);
      }

      if (enrollmentNo != null && enrollmentNo.isNotEmpty) {
        query = query.like('profiles.enrollment_no', '%$enrollmentNo%');
      }

      // Apply ordering and pagination in separate steps
      var orderedQuery = query.order('created_at', ascending: false);
      
      if (limit != null && offset != null) {
        orderedQuery = orderedQuery.range(offset, offset + limit - 1);
      } else if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      print('StudentController.getAllStudentsWithProfiles: Found ${response.length} students');
      print('Sample student data: ${response.isNotEmpty ? response.first : 'No students found'}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload document to Supabase Storage
  Future<String> uploadDocument({
    required String studentId,
    required DocumentType docType,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      print('StudentController.uploadDocument called');
      print('Student ID: $studentId');
      print('Document Type: ${docType.value}');
      print('File Name: $fileName');
      print('File Size: ${fileBytes.length} bytes');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final storagePath = '$studentId/${docType.value}-$timestamp.$fileExtension';
      
      print('Storage Path: $storagePath');

      print('Uploading to Supabase Storage...');
      // Upload to storage
      await _supabase.storage
          .from('student-docs')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      print('Storage upload successful, saving metadata...');
      // Save document metadata
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Session expired. Please sign in again.');
      }

      await _supabase
          .from('student_documents')
          .insert({
            'student_id': studentId,
            'doc_type': docType.value,
            'storage_path': storagePath,
            'uploaded_by': currentUser.id,
            'file_name': fileName,
            'file_size': fileBytes.length,
          });

      return storagePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Get documents for a student
  Future<List<StudentDocument>> getStudentDocuments(String studentId) async {
    try {
      final response = await _supabase
          .from('student_documents')
          .select()
          .eq('student_id', studentId)
          .order('uploaded_at', ascending: false);

      return response
          .map<StudentDocument>((doc) => StudentDocument.fromJson(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get signed URL for document download
  Future<String> getDocumentDownloadUrl(String storagePath) async {
    try {
      final response = await _supabase.storage
          .from('student-docs')
          .createSignedUrl(storagePath, 3600); // 1 hour expiry

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      // Get document info first
      final docResponse = await _supabase
          .from('student_documents')
          .select('storage_path')
          .eq('id', documentId)
          .single();

      // Delete from storage
      await _supabase.storage
          .from('student-docs')
          .remove([docResponse['storage_path']]);

      // Delete metadata
      await _supabase
          .from('student_documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get student statistics (optimized with single query)
  Future<Map<String, dynamic>> getStudentStats() async {
    try {
      // Single optimized query to get all stats at once
      final response = await _supabase
          .from('students')
          .select('class, gender');

      int totalStudents = response.length;
      final Map<String, int> classStats = {};
      final Map<String, int> genderStats = {};

      // Process results in memory (faster than multiple queries)
      for (final student in response) {
        // Count by class
        final className = student['class'] as String? ?? 'Unknown';
        classStats[className] = (classStats[className] ?? 0) + 1;
        
        // Count by gender
        final gender = student['gender'] as String? ?? 'Unknown';
        genderStats[gender] = (genderStats[gender] ?? 0) + 1;
      }

      return {
        'totalStudents': totalStudents,
        'classStats': classStats,
        'genderStats': genderStats,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Search students by enrollment number (limited to 50 results for performance)
  Future<List<Map<String, dynamic>>> searchStudentsByEnrollment(String enrollmentNo) async {
    try {
      final response = await _supabase
          .from('students')
          .select('''
            *,
            profiles!inner(
              id,
              full_name,
              enrollment_no,
              is_staff,
              class,
              profile_photo_path
            )
          ''')
          .ilike('profiles.enrollment_no', '%$enrollmentNo%')
          .order('created_at', ascending: false)
          .limit(50); // Limit search results for better performance

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if student record exists for profile
  Future<bool> studentExists(String profileId) async {
    try {
      final response = await _supabase
          .from('students')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      rethrow;
    }
  }
}
