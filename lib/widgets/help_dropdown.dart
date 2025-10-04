import 'package:flutter/material.dart';
import '../constants/theme.dart';

class HelpDropdown extends StatelessWidget {
  const HelpDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.help_outline,
        color: Colors.white,
      ),
      onSelected: (value) {
        if (value == 'help') {
          _showHelpDialog(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text('Help & Support'),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              'Help & Support',
              style: AppTheme.heading3,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Required Documents Section
              _buildSection(
                icon: Icons.upload_file,
                title: 'Required Documents',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please prepare the following documents for upload:',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildDocumentItem('Aadhaar Card'),
                    _buildDocumentItem('10th Mark Sheet'),
                    _buildDocumentItem('12th Mark Sheet'),
                    _buildDocumentItem('Birth Certificate'),
                    _buildDocumentItem('Community Certificate'),
                    _buildDocumentItem('Income Certificate'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // File Requirements Section
              _buildSection(
                icon: Icons.compress,
                title: 'File Requirements',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.photo, 'Image Formats: JPG, JPEG, PNG'),
                    _buildInfoRow(Icons.picture_as_pdf, 'Document Format: PDF'),
                    _buildInfoRow(Icons.data_usage, 'Max Size: 210 KB per file'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlueTint,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Files larger than 210 KB will be automatically compressed before upload.',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryBlueDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Security Section
              _buildSection(
                icon: Icons.security,
                title: 'Data Security',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your personal details and uploaded documents are:',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.lock, 'End-to-end Encrypted'),
                    _buildInfoRow(Icons.verified_user, 'Role-Based Access Control'),
                    _buildInfoRow(Icons.account_balance, 'Department of Artificial Intelligence & Data Science Only'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your data is safe and can only be accessed by you and authorized personnel.',
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.successColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Contact Information Section
              _buildSection(
                icon: Icons.contact_support,
                title: 'Technical Support',
                content: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlueTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactRow(Icons.person, 'Name:', 'Vishwa P'),
                      _buildContactRow(Icons.school, 'Year:', 'III'),
                      _buildContactRow(Icons.phone, 'Contact:', '9384157111'),
                      _buildContactRow(Icons.email, 'Email:', 'btechaids23159@smvec.ac.in'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTheme.buttonTextDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.heading3.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildDocumentItem(String document) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
          const SizedBox(width: 8),
          Text(document, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(width: 8),
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
