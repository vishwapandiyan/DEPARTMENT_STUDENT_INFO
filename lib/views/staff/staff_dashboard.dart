import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../constants/theme.dart';
import '../../constants/enums.dart';
import '../../models/document.dart';
import '../../models/profile.dart';
import '../../utils/csv_util.dart';
import '../../widgets/staff_profile_photo_widget.dart';
import '../../widgets/help_dropdown.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/enhanced_buttons.dart';
import '../../widgets/animated_loading_card.dart';
import 'student_list_view.dart';
import 'document_preview_dialog.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  @override
  void initState() {
    super.initState();
    // Schedule data loading after the current build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    await Future.wait([
      studentProvider.loadAllStudents(),
      studentProvider.loadStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          // Help dropdown
          const HelpDropdown(),
          const SizedBox(width: 8),
          // User profile dropdown
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.signOut();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(authProvider.profile?.fullName ?? 'Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading && studentProvider.allStudents.isEmpty) {
            return const Center(
              child: AnimatedLoadingCard(
                message: 'Loading dashboard...',
                height: 200,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              color: AppTheme.primaryBlue,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff Dashboard',
                                  style: AppTheme.heading2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage student records and documents',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.lightGrayText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Statistics Cards
                if (studentProvider.stats != null) ...[
                  _buildStatsSection(studentProvider.stats!),
                  const SizedBox(height: AppTheme.spacingL),
                ],

                // Quick Actions
                _buildQuickActionsSection(),

                const SizedBox(height: AppTheme.spacingL),

                // Recent Students
                _buildRecentStudentsSection(studentProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Total Students',
                  value: stats['totalStudents']?.toString() ?? '0',
                  icon: Icons.people,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: StatsCard(
                  title: 'Classes',
                  value: '5',
                  icon: Icons.class_,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.heading2.copyWith(color: color),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentListView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View All Students'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showExportDialog();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStudentsSection(StudentProvider studentProvider) {
    final recentStudents = studentProvider.allStudents.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Students',
                style: AppTheme.heading3,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StudentListView(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (recentStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppTheme.lightGrayText,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No students found',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentStudents.map((student) => _buildStudentListItem(student)).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentListItem(Map<String, dynamic> student) {
    final profile = student['profiles'] as Map<String, dynamic>?;
    final studentData = student;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.lightBlueTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: Text(
              profile?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['full_name'] ?? 'Unknown Student',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enrollment: ${profile?['enrollment_no'] ?? 'N/A'} • Class ${studentData['class'] ?? 'N/A'}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.lightGrayText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _viewStudentDetails(student);
            },
            icon: const Icon(Icons.visibility),
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => StudentDetailsDialog(student: student),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(),
    );
  }
}

class StudentDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentDetailsDialog({super.key, required this.student});

  @override
  State<StudentDetailsDialog> createState() => _StudentDetailsDialogState();
}

class _StudentDetailsDialogState extends State<StudentDetailsDialog> {
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
      title: const Text('Student Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Photo and Basic Info
            Row(
              children: [
                StaffProfilePhotoWidget(
                  profileData: profile,
                  size: 80,
                  showDownloadButton: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?['full_name'] ?? 'Unknown',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enrollment: ${profile?['enrollment_no'] ?? 'N/A'}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.lightGrayText,
                        ),
                      ),
                      Text(
                        'Class: ${widget.student['class'] ?? 'N/A'}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.lightGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Detailed Information
            _buildDetailRow('Gender', widget.student['gender'] ?? 'N/A'),
            _buildDetailRow('Address', widget.student['address'] ?? 'Not provided'),
            _buildDetailRow('Father Name', widget.student['father_name'] ?? 'Not provided'),
            _buildDetailRow('Mother Name', widget.student['mother_name'] ?? 'Not provided'),
            _buildDetailRow('10th %', widget.student['tenth_percent']?.toString() ?? 'Not provided'),
            _buildDetailRow('12th %', widget.student['twelfth_percent']?.toString() ?? 'Not provided'),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Documents Section
            Text(
              'Documents',
              style: AppTheme.heading3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildDocumentsSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _exportSingleStudent(context);
            Navigator.of(context).pop();
          },
          child: const Text('Export CSV'),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    if (_isLoadingDocuments) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_documentsError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            const SizedBox(height: 8),
            Text(
              'Failed to load documents',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadDocuments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.upload_file, color: AppTheme.lightGray),
            const SizedBox(height: 8),
            Text(
              'No documents uploaded',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.lightGray),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _documents.map((doc) => _buildDocumentItem(doc)).toList(),
    );
  }

  Widget _buildDocumentItem(StudentDocument doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(doc.docType),
            color: AppTheme.secondaryGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.docType.displayName,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (doc.fileName != null) ...[
                  Text(
                    doc.fileName!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                  ),
                ],
                Text(
                  'Uploaded: ${doc.uploadedAt.toLocal().toString().split(' ')[0]} • ${doc.fileSizeInKB}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.lightGrayText,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _previewDocument(context, doc),
                icon: const Icon(Icons.visibility),
                color: AppTheme.primaryBlue,
                tooltip: 'Preview ${doc.docType.displayName}',
              ),
              IconButton(
                onPressed: () => _downloadDocument(context, doc),
                icon: const Icon(Icons.download),
                color: AppTheme.primaryBlue,
                tooltip: 'Download ${doc.docType.displayName}',
              ),
            ],
          ),
        ],
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

  void _previewDocument(BuildContext context, StudentDocument doc) {
    showDialog(
      context: context,
      builder: (context) => DocumentPreviewDialog(document: doc),
    );
  }

  Future<void> _downloadDocument(BuildContext context, StudentDocument doc) async {
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  Future<void> _exportSingleStudent(BuildContext context) async {
    try {
      final profile = widget.student['profiles'] as Map<String, dynamic>?;
      if (profile != null) {
        final csvContent = CsvUtil.generateStudentsCsv([widget.student]);
        final fileName = CsvUtil.generateFileName(
          'Student_${profile['enrollment_no']?.toString() ?? 'Unknown'}',
        );
        
        await CsvUtil.downloadCsv(csvContent, fileName);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student data exported successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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

class ExportDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Export All Students'),
            subtitle: const Text('Download CSV with all student data'),
            onTap: () async {
              Navigator.of(context).pop();
              await _exportAllStudents(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Export by Class'),
            subtitle: const Text('Download CSV for specific class'),
            onTap: () {
              Navigator.of(context).pop();
              _showClassExportDialog(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _exportAllStudents(BuildContext context) async {
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.loadAllStudents();
      
      final students = studentProvider.allStudents;
      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No students found to export'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      final csvContent = CsvUtil.generateStudentsCsv(students);
      final fileName = CsvUtil.generateFileName('All_Students');
      
      await CsvUtil.downloadCsv(csvContent, fileName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All students data exported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showClassExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export by Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StudentClass.values.map((studentClass) {
            return ListTile(
              leading: const Icon(Icons.school),
              title: Text('Class ${studentClass.value}'),
              onTap: () async {
                Navigator.of(context).pop();
                await _exportByClass(context, studentClass);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportByClass(BuildContext context, StudentClass studentClass) async {
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.loadAllStudents();
      
      final allStudents = studentProvider.allStudents;
      final classStudents = allStudents.where((student) {
        final studentData = student['class'] as String?;
        return studentData == studentClass.value;
      }).toList();

      if (classStudents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No students found in class ${studentClass.value}'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      final csvContent = CsvUtil.generateStudentsCsv(classStudents);
      final fileName = CsvUtil.generateFileName('Students_Class_${studentClass.value}');
      
      await CsvUtil.downloadCsv(csvContent, fileName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class ${studentClass.value} data exported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
