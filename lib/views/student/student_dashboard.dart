import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../constants/theme.dart';
import '../../utils/csv_util.dart';
import '../../widgets/profile_photo_widget.dart';
import '../../widgets/help_dropdown.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/enhanced_buttons.dart';
import '../../widgets/animated_loading_card.dart';
import 'student_form.dart';
import 'student_profile_view.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    // Schedule data loading after the current build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentData();
    });
  }

  Future<void> _loadStudentData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    if (authProvider.profile != null) {
      await studentProvider.loadStudent(authProvider.profile!.id);
    }
  }

  Future<void> _downloadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    if (authProvider.profile != null && studentProvider.student != null) {
      final csvContent = CsvUtil.generateStudentCsvFromObjects(
        studentProvider.student!,
        authProvider.profile!,
      );
      
      final fileName = CsvUtil.generateFileName(
        'Student_Profile_${authProvider.profile!.enrollmentNo}',
      );
      
      CsvUtil.downloadCsv(csvContent, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile downloaded successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
      body: Consumer2<AuthProvider, StudentProvider>(
        builder: (context, authProvider, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(
              child: AnimatedLoadingCard(
                message: 'Loading your profile...',
                height: 200,
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStudentData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final hasStudent = studentProvider.hasStudent;
          final profile = authProvider.profile;

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
                          // Profile Photo
                          ProfilePhotoWidget(
                            size: 80,
                            onPhotoChanged: () {
                              // Refresh the dashboard when photo changes
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${profile?.fullName ?? 'Student'}!',
                                  style: AppTheme.heading2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enrollment: ${profile?.enrollmentNo ?? 'N/A'}',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.lightGrayText,
                                  ),
                                ),
                                if (profile?.studentClass != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Class: ${profile!.studentClass!.value}',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.lightGrayText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Profile Status Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasStudent ? Icons.check_circle : Icons.info,
                            color: hasStudent ? AppTheme.successColor : AppTheme.warningColor,
                            size: 24,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Profile Status',
                            style: AppTheme.heading3,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        hasStudent 
                            ? 'Your profile is set up. You can view and edit your information.'
                            : 'Please complete your student profile to access all features.',
                        style: AppTheme.bodyMedium,
                      ),
                      if (hasStudent && studentProvider.student != null) ...[
                        const SizedBox(height: AppTheme.spacingM),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: studentProvider.student!.isProfileComplete
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                studentProvider.student!.isProfileComplete
                                    ? Icons.check_circle_outline
                                    : Icons.warning_outlined,
                                color: studentProvider.student!.isProfileComplete
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Expanded(
                                child: Text(
                                  studentProvider.student!.isProfileComplete
                                      ? 'Profile is complete'
                                      : 'Profile needs completion',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: studentProvider.student!.isProfileComplete
                                        ? AppTheme.successColor
                                        : AppTheme.warningColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Action Buttons
                if (!hasStudent) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StudentForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create Profile'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const StudentForm(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const StudentProfileView(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Profile'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  EnhancedButton(
                    text: 'Download Profile (CSV)',
                    onPressed: _downloadProfile,
                    icon: Icons.download,
                    type: ButtonType.secondary,
                    size: ButtonSize.medium,
                    fullWidth: true,
                  ),
                ],

                const SizedBox(height: AppTheme.spacingL),

                // Documents Section
                if (hasStudent) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents',
                          style: AppTheme.heading3,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'Upload and manage your documents. Each file must be under 210 KB.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.lightGrayText,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const StudentForm(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Manage Documents'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
