import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../../providers/student_provider.dart';
import '../../constants/enums.dart';
import '../../constants/theme.dart';
import '../../models/document.dart';
import '../../models/profile.dart';
import '../../utils/csv_util.dart';
import '../../widgets/staff_profile_photo_widget.dart';
import 'document_preview_dialog.dart';

class StudentListView extends StatefulWidget {
  const StudentListView({super.key});

  @override
  State<StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<StudentListView> {
  final _searchController = TextEditingController();
  StudentClass? _selectedClass;
  StudentGender? _selectedGender;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Schedule data loading after the current build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    await studentProvider.loadAllStudents(resetPagination: true);
  }

  Future<void> _searchStudents() async {
    if (_searchController.text.trim().isEmpty) {
      _loadStudents();
      return;
    }

    setState(() => _isSearching = true);
    
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    await studentProvider.searchStudentsByEnrollment(_searchController.text.trim());
    
    setState(() => _isSearching = false);
  }

  Future<void> _applyFilters() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    await studentProvider.loadAllStudents(
      studentClass: _selectedClass,
      gender: _selectedGender,
      resetPagination: true,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedClass = null;
      _selectedGender = null;
      _searchController.clear();
    });
    _loadStudents();
  }

  Future<void> _exportAllStudents() async {
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final students = studentProvider.allStudents;
      
      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students found to export'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }

      final csvContent = CsvUtil.generateStudentsCsv(students);
      final fileName = CsvUtil.generateFileName('All_Students');
      
      await CsvUtil.downloadCsv(csvContent, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All students data exported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportByClass(StudentClass studentClass) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    // Filter students by class
    final allStudents = studentProvider.allStudents;
    final classStudents = allStudents.where((student) {
      final studentClassData = student['class'] as String?;
      return studentClassData == studentClass.value;
    }).toList();

    if (classStudents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No students found in class ${studentClass.value}'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    final csvContent = CsvUtil.generateClassCsv(classStudents);
    final fileName = CsvUtil.generateFileName('Students_Class_${studentClass.value}');
    
    await CsvUtil.downloadCsv(csvContent, fileName);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Class ${studentClass.value} data exported successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: [
          IconButton(
            onPressed: _exportAllStudents,
            icon: const Icon(Icons.download),
            tooltip: 'Export All Students',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by enrollment number...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadStudents();
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _searchStudents(),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    ElevatedButton(
                      onPressed: _searchStudents,
                      child: _isSearching
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<StudentClass>(
                        value: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<StudentClass>(
                            value: null,
                            child: Text('All Classes'),
                          ),
                          ...StudentClass.values.map((studentClass) {
                            return DropdownMenuItem<StudentClass>(
                              value: studentClass,
                              child: Text('Class ${studentClass.value}'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClass = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: DropdownButtonFormField<StudentGender>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<StudentGender>(
                            value: null,
                            child: Text('All Genders'),
                          ),
                          ...StudentGender.values.map((gender) {
                            return DropdownMenuItem<StudentGender>(
                              value: gender,
                              child: Text(gender.value.toUpperCase()),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, studentProvider, child) {
                if (studentProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading students...'),
                      ],
                    ),
                  );
                }

                if (studentProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading students',
                          style: AppTheme.heading2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          studentProvider.error!,
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStudents,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final students = studentProvider.allStudents;
                print('StudentListView: allStudents count = ${students.length}');
                print('StudentListView: isLoading = ${studentProvider.isLoading}');
                print('StudentListView: error = ${studentProvider.error}');

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.lightGrayText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: AppTheme.heading2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search criteria or filters',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentCard(student);
                        },
                      ),
                    ),
                    // Load More Button
                    if (studentProvider.hasMoreData)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: ElevatedButton(
                          onPressed: studentProvider.isLoading ? null : () {
                            studentProvider.loadMoreStudents(
                              studentClass: _selectedClass,
                              gender: _selectedGender,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: studentProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Load More Students (${students.length} loaded)'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final profile = student['profiles'] as Map<String, dynamic>?;
    final studentData = student;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: ListTile(
        leading: StaffProfilePhotoWidget(
          profileData: profile,
          size: 40,
          showDownloadButton: true,
        ),
        title: Text(
          profile?['full_name'] ?? 'Unknown Student',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrollment: ${profile?['enrollment_no'] ?? 'N/A'}',
              style: AppTheme.bodySmall,
            ),
            Text(
              'Class ${studentData['class'] ?? 'N/A'} • ${studentData['gender']?.toString().toUpperCase() ?? 'N/A'}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.lightGrayText,
              ),
            ),
            if (studentData['tenth_percent'] != null || studentData['twelfth_percent'] != null)
              Text(
                '10th: ${studentData['tenth_percent']?.toString() ?? 'N/A'}% • 12th: ${studentData['twelfth_percent']?.toString() ?? 'N/A'}%',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.lightGrayText,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _viewStudentDetails(student);
                break;
              case 'documents':
                _viewStudentDocuments(student);
                break;
              case 'export':
                _exportStudent(student);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'documents',
              child: Row(
                children: [
                  Icon(Icons.attach_file),
                  SizedBox(width: 8),
                  Text('View Documents'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Export CSV'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => StudentDetailsDialog(student: student),
    );
  }

  void _viewStudentDocuments(Map<String, dynamic> student) {
    final profile = student['profiles'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (context) => StudentDocumentsDialog(
        student: student,
        studentName: profile?['full_name'] ?? 'Unknown Student',
      ),
    );
  }

  Future<void> _exportStudent(Map<String, dynamic> student) async {
    try {
      final profile = student['profiles'] as Map<String, dynamic>?;
      if (profile != null) {
        final csvContent = CsvUtil.generateStudentsCsv([student]);
        final fileName = CsvUtil.generateFileName(
          'Student_${profile['enrollment_no']?.toString() ?? 'Unknown'}',
        );
        
        await CsvUtil.downloadCsv(csvContent, fileName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student data exported successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class StudentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailsDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final profile = student['profiles'] as Map<String, dynamic>?;
    
    return AlertDialog(
      title: const Text('Student Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Name', profile?['full_name'] ?? 'Unknown'),
            _buildDetailRow('Enrollment', profile?['enrollment_no'] ?? 'N/A'),
            _buildDetailRow('Class', student['class'] ?? 'N/A'),
            _buildDetailRow('Gender', student['gender'] ?? 'N/A'),
            _buildDetailRow('Date of Birth', student['dob'] ?? 'Not provided'),
            _buildDetailRow('Address', student['address'] ?? 'Not provided'),
            _buildDetailRow('Father Name', student['father_name'] ?? 'Not provided'),
            _buildDetailRow('Mother Name', student['mother_name'] ?? 'Not provided'),
            _buildDetailRow('Guardian Name', student['guardian_name'] ?? 'Not provided'),
            _buildDetailRow('Community', student['community'] ?? 'Not provided'),
            _buildDetailRow('10th Percentage', student['tenth_percent']?.toString() ?? 'Not provided'),
            _buildDetailRow('12th Percentage', student['twelfth_percent']?.toString() ?? 'Not provided'),
            _buildDetailRow('Father Income', student['father_income']?.toString() ?? 'Not provided'),
            _buildDetailRow('Mother Income', student['mother_income']?.toString() ?? 'Not provided'),
            _buildDetailRow('Siblings', student['siblings'] == true ? 'Yes' : 'No'),
            _buildDetailRow('Created', student['created_at']?.toString().split('T')[0] ?? 'Unknown'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            final csvContent = CsvUtil.generateStudentsCsv([student]);
            final fileName = CsvUtil.generateFileName(
              'Student_${profile?['enrollment_no']?.toString()}',
            );
            
            CsvUtil.downloadCsv(csvContent, fileName);
            
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student data exported successfully!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          },
          child: const Text('Export CSV'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightGrayText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDocumentsDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final String studentName;

  const StudentDocumentsDialog({
    super.key,
    required this.student,
    required this.studentName,
  });

  @override
  State<StudentDocumentsDialog> createState() => _StudentDocumentsDialogState();
}

class _StudentDocumentsDialogState extends State<StudentDocumentsDialog> {
  List<StudentDocument> _documents = [];
  bool _isLoadingDocuments = false;
  String? _documentsError;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
      _documentsError = null;
    });

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final documents = await studentProvider.loadDocumentsForStudent(widget.student['id']);
      setState(() {
        _documents = documents;
        _isLoadingDocuments = false;
      });
    } catch (e) {
      setState(() {
        _documentsError = e.toString();
        _isLoadingDocuments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.student['profiles'] as Map<String, dynamic>?;
    
    return AlertDialog(
      title: Row(
        children: [
          StaffProfilePhotoWidget(
            profileData: profile,
            size: 32,
            showDownloadButton: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Documents - ${widget.studentName}'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildDocumentsContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDocumentsContent() {
    if (_isLoadingDocuments) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_documentsError != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load documents',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor),
            ),
            const SizedBox(height: 8),
            Text(
              _documentsError!,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.lightGrayText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, color: AppTheme.lightGrayText, size: 48),
            const SizedBox(height: 16),
            Text(
              'No documents uploaded',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.lightGrayText),
            ),
            const SizedBox(height: 8),
            Text(
              'This student has not uploaded any documents yet.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.lightGrayText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: _documents.map((doc) => _buildDocumentCard(doc)).toList(),
      ),
    );
  }

  Widget _buildDocumentCard(StudentDocument doc) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDocumentIcon(doc.docType),
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.docType.displayName,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (doc.fileName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      doc.fileName!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.lightGrayText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.lightGrayText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Uploaded: ${doc.uploadedAt.toLocal().toString().split(' ')[0]}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.lightGrayText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.storage,
                        size: 14,
                        color: AppTheme.lightGrayText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doc.fileSizeInKB,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.lightGrayText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _previewDocument(doc),
                  icon: const Icon(Icons.visibility),
                  color: AppTheme.primaryBlue,
                  tooltip: 'Preview ${doc.docType.displayName}',
                ),
                IconButton(
                  onPressed: () => _downloadDocument(doc),
                  icon: const Icon(Icons.download),
                  color: AppTheme.primaryBlue,
                  tooltip: 'Download ${doc.docType.displayName}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType docType) {
    switch (docType) {
      case DocumentType.aadhaar:
        return Icons.credit_card;
      case DocumentType.tenth:
        return Icons.school;
      case DocumentType.twelfth:
        return Icons.school;
      case DocumentType.birthCert:
        return Icons.description;
      case DocumentType.community:
        return Icons.article;
      case DocumentType.income:
        return Icons.account_balance;
    }
  }

  void _previewDocument(StudentDocument doc) {
    showDialog(
      context: context,
      builder: (context) => DocumentPreviewDialog(document: doc),
    );
  }

  Future<void> _downloadDocument(StudentDocument doc) async {
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final downloadUrl = await studentProvider.getDocumentDownloadUrlForStaff(doc.storagePath);
      
      if (downloadUrl != null && mounted) {
        // For web, we can open the URL directly
        if (kIsWeb) {
          // ignore: avoid_web_libraries_in_flutter
          html.window.open(downloadUrl, '_blank');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${doc.docType.displayName}...'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
