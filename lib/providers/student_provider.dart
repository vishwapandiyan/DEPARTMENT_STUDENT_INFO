import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/student.dart';
import '../models/document.dart';
import '../controllers/student_controller.dart';
import '../constants/enums.dart';
import '../utils/compress_util.dart';
import '../utils/user_friendly_errors.dart';

class StudentProvider extends ChangeNotifier {
  final StudentController _studentController = StudentController();

  Student? _student;
  List<StudentDocument> _documents = [];
  List<Map<String, dynamic>> _allStudents = [];
  Map<String, dynamic>? _stats;
  
  // Pagination state
  int _currentPage = 0;
  int _pageSize = 20;
  bool _hasMoreData = true;
  int _totalCount = 0;
  
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  // Getters
  Student? get student => _student;
  List<StudentDocument> get documents => _documents;
  List<Map<String, dynamic>> get allStudents => _allStudents;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  bool get hasStudent => _student != null;
  
  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasMoreData => _hasMoreData;
  int get totalCount => _totalCount;

  /// Load student data by profile ID
  Future<void> loadStudent(String profileId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _student = await _studentController.getStudentByProfileId(profileId);
      if (_student != null) {
        await _loadDocuments(_student!.id);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load student by student ID
  Future<void> loadStudentById(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _student = await _studentController.getStudentById(studentId);
      if (_student != null) {
        await _loadDocuments(_student!.id);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save student data
  Future<Student?> saveStudent(Student student) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _student = await _studentController.saveStudent(student);
      _isLoading = false;
      notifyListeners();
      return _student;
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load documents for a student
  Future<void> _loadDocuments(String studentId) async {
    try {
      _documents = await _studentController.getStudentDocuments(studentId);
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      notifyListeners();
    }
  }

  /// Upload document with compression
  Future<bool> uploadDocument({
    required DocumentType docType,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    print('StudentProvider.uploadDocument called for: $fileName');
    
    if (_student == null) {
      print('Error: Student record is null');
      _error = 'Student data not loaded';
      notifyListeners();
      return false;
    }

    print('Student ID: ${_student!.id}');

    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate file type
      if (!CompressionUtil.isValidFileType(fileName)) {
        _error = 'Invalid file type. Please upload JPG, PNG, or PDF files only.';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // Compress image files only if they exceed 210KB (with timeout)
      Uint8List compressedBytes = fileBytes;
      if (RegExp(r'\.(jpg|jpeg|png)$').hasMatch(fileName.toLowerCase()) && 
          fileBytes.length > CompressionUtil.maxFileSizeBytes) {
        compressedBytes = await CompressionUtil.compressImage(fileBytes)
            .timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception('File compression timed out. Please try with a smaller file.');
        });
      }

      // Check final file size
      if (!CompressionUtil.isAcceptableFileSize(compressedBytes.length)) {
        _error = 'File size too large. ${CompressionUtil.getCompressionTips()}';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      print('Calling StudentController.uploadDocument...');
      // Upload to storage (with timeout)
      await _studentController.uploadDocument(
        studentId: _student!.id,
        docType: docType,
        fileBytes: compressedBytes,
        fileName: fileName,
      ).timeout(const Duration(minutes: 2), onTimeout: () {
        throw Exception('Upload timed out. Please check your internet connection and try again.');
      });

      print('Upload to storage successful, reloading documents...');
      // Reload documents
      await _loadDocuments(_student!.id);
      _isUploading = false;
      notifyListeners();
      print('Upload completed successfully');
      return true;
    } catch (e) {
      print('Error in StudentProvider.uploadDocument: $e');
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get download URL for document
  Future<String?> getDocumentDownloadUrl(String storagePath) async {
    try {
      return await _studentController.getDocumentDownloadUrl(storagePath);
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String documentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _studentController.deleteDocument(documentId);
      await _loadDocuments(_student!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load all students (for staff) with pagination
  Future<void> loadAllStudents({
    StudentClass? studentClass,
    StudentGender? gender,
    String? enrollmentNo,
    int? limit,
    int? offset,
    bool resetPagination = false,
  }) async {
    _isLoading = true;
    _error = null;
    
    if (resetPagination) {
      _currentPage = 0;
      _allStudents.clear();
      _hasMoreData = true;
    }
    
    notifyListeners();

    try {
      // Default pagination: 20 students per page for better performance
      final pageLimit = limit ?? _pageSize;
      final pageOffset = offset ?? (_currentPage * _pageSize);
      
      final students = await _studentController.getAllStudentsWithProfiles(
        studentClass: studentClass,
        gender: gender,
        enrollmentNo: enrollmentNo,
        limit: pageLimit,
        offset: pageOffset,
      );
      
      if (resetPagination) {
        _allStudents = students;
      } else {
        _allStudents.addAll(students);
      }
      
      // Check if we have more data
      _hasMoreData = students.length == pageLimit;
      _currentPage++;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more students (for pagination)
  Future<void> loadMoreStudents({
    StudentClass? studentClass,
    StudentGender? gender,
    String? enrollmentNo,
  }) async {
    if (!_hasMoreData || _isLoading) return;
    
    await loadAllStudents(
      studentClass: studentClass,
      gender: gender,
      enrollmentNo: enrollmentNo,
      resetPagination: false,
    );
  }

  /// Search students by enrollment number with pagination
  Future<void> searchStudentsByEnrollment(String enrollmentNo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Limit search results to 50 for better performance
      _allStudents = await _studentController.searchStudentsByEnrollment(enrollmentNo);
      _currentPage = 0;
      _hasMoreData = false; // Search results are limited
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load statistics
  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _studentController.getStudentStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if student exists for profile
  Future<bool> studentExists(String profileId) async {
    try {
      return await _studentController.studentExists(profileId);
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Get document by type
  StudentDocument? getDocumentByType(DocumentType docType) {
    try {
      return _documents.firstWhere(
        (doc) => doc.docType == docType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if document exists for type
  bool hasDocument(DocumentType docType) {
    return getDocumentByType(docType) != null;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load documents for any student (for staff viewing)
  Future<List<StudentDocument>> loadDocumentsForStudent(String studentId) async {
    try {
      return await _studentController.getStudentDocuments(studentId);
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Get download URL for document (for staff viewing)
  Future<String?> getDocumentDownloadUrlForStaff(String storagePath) async {
    try {
      return await _studentController.getDocumentDownloadUrl(storagePath);
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Clear all data
  void clearData() {
    _student = null;
    _documents.clear();
    _allStudents.clear();
    _stats = null;
    _error = null;
    notifyListeners();
  }
}
