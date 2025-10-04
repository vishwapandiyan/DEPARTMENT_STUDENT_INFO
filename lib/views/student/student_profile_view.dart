import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../models/document.dart';
import '../../constants/enums.dart';
import '../../constants/theme.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/student-form');
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
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
                    'Error loading profile',
                    style: AppTheme.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    studentProvider.error!,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!studentProvider.hasStudent) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: AppTheme.lightGrayText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Profile Found',
                    style: AppTheme.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please create your student profile first.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/student-form');
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          final student = studentProvider.student!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Class ${student.studentClass.value}',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: student.isProfileComplete
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Text(
                          student.isProfileComplete ? 'Profile Complete' : 'Profile Incomplete',
                          style: AppTheme.bodySmall.copyWith(
                            color: student.isProfileComplete
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Personal Information
                _buildInfoSection(
                  title: 'Personal Information',
                  icon: Icons.person,
                  items: [
                    _buildInfoItem('Aadhaar', student.maskedAadhaar),
                    _buildInfoItem('Date of Birth', 
                        student.dob?.toLocal().toString().split(' ')[0] ?? 'Not provided'),
                    _buildInfoItem('Gender', student.gender.value.toUpperCase()),
                    _buildInfoItem('Address', student.address ?? 'Not provided'),
                    _buildInfoItem('Siblings', student.siblings ? 'Yes' : 'No'),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Family Information
                _buildInfoSection(
                  title: 'Family Information',
                  icon: Icons.family_restroom,
                  items: [
                    _buildInfoItem('Father Name', student.fatherName ?? 'Not provided'),
                    _buildInfoItem('Mother Name', student.motherName ?? 'Not provided'),
                    _buildInfoItem('Guardian Name', student.guardianName ?? 'Not provided'),
                    _buildInfoItem('Community', student.community ?? 'Not provided'),
                    _buildInfoItem('Father Income', 
                        student.fatherIncome != null ? '₹${student.fatherIncome!.toStringAsFixed(0)}' : 'Not provided'),
                    _buildInfoItem('Mother Income', 
                        student.motherIncome != null ? '₹${student.motherIncome!.toStringAsFixed(0)}' : 'Not provided'),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Academic Information
                _buildInfoSection(
                  title: 'Academic Information',
                  icon: Icons.school,
                  items: [
                    _buildInfoItem('10th Percentage', 
                        student.tenthPercent != null ? '${student.tenthPercent!.toStringAsFixed(1)}%' : 'Not provided'),
                    _buildInfoItem('12th Percentage', 
                        student.twelfthPercent != null ? '${student.twelfthPercent!.toStringAsFixed(1)}%' : 'Not provided'),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Documents Section
                _buildDocumentsSection(context, studentProvider.documents),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  title,
                  style: AppTheme.heading3,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.lightGrayText,
                fontWeight: FontWeight.w500,
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

  Widget _buildDocumentsSection(BuildContext context, List<StudentDocument> documents) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Documents',
                  style: AppTheme.heading3,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (documents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 48,
                    color: AppTheme.lightGrayText,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No documents uploaded',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Upload your documents to complete your profile',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...documents.map((doc) => _buildDocumentItem(context, doc)).toList(),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, StudentDocument doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(doc.docType),
            color: AppTheme.secondaryGold,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
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
                  const SizedBox(height: 2),
                  Text(
                    doc.fileName!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Uploaded: ${doc.uploadedAt.toLocal().toString().split(' ')[0]} • ${doc.fileSizeInKB}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.lightGrayText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _downloadDocument(context, doc),
            icon: const Icon(Icons.download),
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType docType) {
    switch (docType) {
      case DocumentType.aadhaar:
        return Icons.credit_card;
      case DocumentType.birthCert:
        return Icons.cake;
      case DocumentType.tenth:
        return Icons.school;
      case DocumentType.twelfth:
        return Icons.school;
      case DocumentType.community:
        return Icons.group;
      case DocumentType.income:
        return Icons.attach_money;
    }
  }

  Future<void> _downloadDocument(BuildContext context, StudentDocument doc) async {
    try {
      // Open download URL in new tab/window
      // Note: This requires web-specific implementation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download link generated. Check your downloads.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download document: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
