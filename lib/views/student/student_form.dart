import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student.dart';
import '../../constants/enums.dart';
import '../../constants/theme.dart';
import '../../utils/validators.dart';
import '../../utils/compress_util.dart';
import '../../widgets/enhanced_upload_progress.dart';
import '../../widgets/enhanced_buttons.dart';
import '../../widgets/enhanced_cards.dart';
import '../../widgets/animated_loading_card.dart';

class StudentForm extends StatefulWidget {
  const StudentForm({super.key});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  int _currentPage = 0;
  final int _totalPages = 4;

  // Form controllers
  final _aadhaarController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _communityController = TextEditingController();
  final _tenthPercentController = TextEditingController();
  final _twelfthPercentController = TextEditingController();
  final _fatherIncomeController = TextEditingController();
  final _motherIncomeController = TextEditingController();

  // Form data
  DateTime? _selectedDob;
  StudentGender _selectedGender = StudentGender.male;
  StudentClass _selectedClass = StudentClass.a;
  bool _hasSiblings = false;
  
  // Document uploads
  final Map<DocumentType, Uint8List?> _documentFiles = {};
  final Map<DocumentType, String> _documentFileNames = {};
  final Map<DocumentType, bool> _documentUploading = {};
  final Map<DocumentType, bool> _documentCompressing = {};
  final Map<DocumentType, String> _documentStatus = {};
  bool _isUploadingAll = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _guardianNameController.dispose();
    _motherNameController.dispose();
    _fatherNameController.dispose();
    _communityController.dispose();
    _tenthPercentController.dispose();
    _twelfthPercentController.dispose();
    _fatherIncomeController.dispose();
    _motherIncomeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (studentProvider.student != null) {
      final student = studentProvider.student!;
      _aadhaarController.text = student.aadhaar ?? '';
      _selectedDob = student.dob;
      _dobController.text = student.dob?.toLocal().toString().split(' ')[0] ?? '';
      _addressController.text = student.address ?? '';
      _guardianNameController.text = student.guardianName ?? '';
      _motherNameController.text = student.motherName ?? '';
      _fatherNameController.text = student.fatherName ?? '';
      _communityController.text = student.community ?? '';
      _tenthPercentController.text = student.tenthPercent?.toString() ?? '';
      _twelfthPercentController.text = student.twelfthPercent?.toString() ?? '';
      _fatherIncomeController.text = student.fatherIncome?.toString() ?? '';
      _motherIncomeController.text = student.motherIncome?.toString() ?? '';
      _selectedGender = student.gender;
      _selectedClass = student.studentClass;
      _hasSiblings = student.siblings;
    } else if (authProvider.profile?.studentClass != null) {
      _selectedClass = authProvider.profile!.studentClass!;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDob = date;
        _dobController.text = date.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _pickDocument(DocumentType docType) async {
    try {
      print('Picking document for: ${docType.displayName}');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      print('File picker result: $result');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('Selected file: ${file.name}, size: ${file.bytes?.length} bytes');
        
        if (file.bytes != null) {
          setState(() {
            _documentFiles[docType] = file.bytes;
            _documentFileNames[docType] = file.name;
            _documentStatus[docType] = 'Selected: ${CompressionUtil.formatFileSize(file.bytes!.length)}';
          });

          // Check if compression is needed
          if (file.bytes!.length > CompressionUtil.maxFileSizeBytes && 
              RegExp(r'\.(jpg|jpeg|png)$').hasMatch(file.name.toLowerCase())) {
            _compressDocument(docType);
          }
        }
      }
    } catch (e) {
      print('Error in _pickDocument: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _compressDocument(DocumentType docType) async {
    if (_documentFiles[docType] == null) return;

    setState(() {
      _documentCompressing[docType] = true;
      _documentStatus[docType] = 'Compressing...';
    });

    try {
      final originalBytes = _documentFiles[docType]!;
      final compressedBytes = await CompressionUtil.compressImage(originalBytes);
      
      setState(() {
        _documentFiles[docType] = compressedBytes;
        _documentCompressing[docType] = false;
        _documentStatus[docType] = 'Compressed: ${CompressionUtil.formatFileSize(compressedBytes.length)}';
      });
    } catch (e) {
      setState(() {
        _documentCompressing[docType] = false;
        _documentStatus[docType] = 'Compression failed: $e';
      });
    }
  }

  Future<void> _uploadDocument(DocumentType docType) async {
    if (_documentFiles[docType] == null) return;

    setState(() {
      _documentUploading[docType] = true;
      _documentStatus[docType] = 'Uploading...';
    });

    try {
      print('Starting document upload for: ${docType.displayName}');
      
      // Ensure student record exists first
      print('Saving student record...');
      await _saveStudentRecord();
      print('Student record saved successfully');
      
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      print('Calling uploadDocument with student ID: ${studentProvider.student?.id}');
      
      final success = await studentProvider.uploadDocument(
        docType: docType,
        fileBytes: _documentFiles[docType]!,
        fileName: _documentFileNames[docType] ?? 'document',
      );

      print('Upload result: $success');

      setState(() {
        _documentUploading[docType] = false;
        if (success) {
          _documentStatus[docType] = 'Uploaded successfully!';
          _documentFiles.remove(docType);
          _documentFileNames.remove(docType);
        } else {
          _documentStatus[docType] = 'Upload failed - check console for details';
        }
      });
    } catch (e) {
      print('Error in _uploadDocument: $e');
      setState(() {
        _documentUploading[docType] = false;
        _documentStatus[docType] = 'Upload failed: $e';
      });
    }
  }

  Future<void> _uploadAllDocuments() async {
    setState(() {
      _isUploadingAll = true;
    });

    try {
      // First, ensure student record exists
      await _saveStudentRecord();
      
      final documentsToUpload = DocumentType.values
          .where((docType) => _documentFiles.containsKey(docType) && _documentFiles[docType] != null)
          .toList();

      for (final docType in documentsToUpload) {
        await _uploadDocument(docType);
      }

      setState(() {
        _isUploadingAll = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All documents uploaded successfully!'),
            backgroundColor: AppTheme.secondaryGold,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingAll = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _previewDocument(DocumentType docType) {
    if (_documentFiles[docType] == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Preview: ${docType.displayName}',
                style: AppTheme.heading3,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Expanded(
                child: Image.memory(
                  _documentFiles[docType]!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _documentFileNames[docType] ?? 'Unknown file',
                    style: AppTheme.bodyMedium,
                  ),
                  Text(
                    CompressionUtil.formatFileSize(_documentFiles[docType]!.length),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveStudentRecord() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    if (authProvider.profile == null) {
      throw Exception('Profile not found. Please contact support if this issue persists.');
    }
    
    // Skip loading existing student - we'll create/update directly
    
    // Create student object from current form data
    final student = Student(
      id: studentProvider.student?.id ?? '',
      profileId: authProvider.profile!.id,
      aadhaar: _aadhaarController.text.isNotEmpty ? _aadhaarController.text : null,
      dob: _selectedDob,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      guardianName: _guardianNameController.text.isNotEmpty ? _guardianNameController.text : null,
      motherName: _motherNameController.text.isNotEmpty ? _motherNameController.text : null,
      fatherName: _fatherNameController.text.isNotEmpty ? _fatherNameController.text : null,
      siblings: _hasSiblings,
      community: _communityController.text.isNotEmpty ? _communityController.text : null,
      tenthPercent: _tenthPercentController.text.isNotEmpty
          ? double.tryParse(_tenthPercentController.text)
          : null,
      twelfthPercent: _twelfthPercentController.text.isNotEmpty
          ? double.tryParse(_twelfthPercentController.text)
          : null,
      fatherIncome: _fatherIncomeController.text.isNotEmpty
          ? double.tryParse(_fatherIncomeController.text)
          : null,
      motherIncome: _motherIncomeController.text.isNotEmpty
          ? double.tryParse(_motherIncomeController.text)
          : null,
      gender: _selectedGender,
      studentClass: _selectedClass,
      createdAt: studentProvider.student?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final savedStudent = await studentProvider.saveStudent(student);
    print('Student saved with ID: ${savedStudent?.id}');
    
    if (savedStudent == null) {
      throw Exception('Failed to save student record');
    }
  }

  Future<void> _saveProfile() async {
    print('_saveProfile called');
    
    if (_formKey.currentState == null) {
      print('Form key currentState is null');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    print('Form validation passed');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    if (authProvider.profile == null) {
      print('Auth profile is null');
      return;
    }
    print('Auth profile found: ${authProvider.profile!.id}');

    final student = Student(
      id: studentProvider.student?.id ?? '',
      profileId: authProvider.profile!.id,
      aadhaar: Validators.sanitizeAadhaar(_aadhaarController.text),
      dob: _selectedDob,
      address: _addressController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
      motherName: _motherNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      siblings: _hasSiblings,
      community: _communityController.text.trim(),
      tenthPercent: _tenthPercentController.text.isNotEmpty
          ? double.tryParse(_tenthPercentController.text)
          : null,
      twelfthPercent: _twelfthPercentController.text.isNotEmpty
          ? double.tryParse(_twelfthPercentController.text)
          : null,
      fatherIncome: _fatherIncomeController.text.isNotEmpty
          ? double.tryParse(_fatherIncomeController.text)
          : null,
      motherIncome: _motherIncomeController.text.isNotEmpty
          ? double.tryParse(_motherIncomeController.text)
          : null,
      gender: _selectedGender,
      studentClass: _selectedClass,
      createdAt: studentProvider.student?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('About to save student data...');
    final savedStudent = await studentProvider.saveStudent(student);
    print('Student save result: ${savedStudent?.id}');
    
    if (savedStudent != null && mounted) {
      print('Profile saved successfully, showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      print('Navigating back...');
      Navigator.of(context).pop();
    } else {
      print('Profile save failed or widget not mounted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal Information',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Aadhaar
          TextFormField(
            controller: _aadhaarController,
            decoration: const InputDecoration(
              labelText: 'Aadhaar Number',
              prefixIcon: Icon(Icons.badge),
              helperText: '12-digit Aadhaar number',
            ),
            validator: Validators.validateAadhaar,
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Date of Birth
          TextFormField(
            controller: _dobController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            onTap: _selectDate,
            validator: (value) => Validators.validateDateOfBirth(_selectedDob),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Gender
          DropdownButtonFormField<StudentGender>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.person),
            ),
            items: StudentGender.values.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender.value.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGender = value;
                });
              }
            },
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Class
          DropdownButtonFormField<StudentClass>(
            value: _selectedClass,
            decoration: const InputDecoration(
              labelText: 'Class',
              prefixIcon: Icon(Icons.class_),
            ),
            items: StudentClass.values.map((studentClass) {
              return DropdownMenuItem(
                value: studentClass,
                child: Text('Class ${studentClass.value}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedClass = value;
                });
              }
            },
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Address
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: Validators.validateAddress,
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Siblings
          CheckboxListTile(
            title: const Text('Do you have siblings?'),
            value: _hasSiblings,
            onChanged: (value) {
              setState(() {
                _hasSiblings = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Family Information',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Father Name
          TextFormField(
            controller: _fatherNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Father Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => Validators.validateRequired(value, 'Father Name'),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Mother Name
          TextFormField(
            controller: _motherNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Mother Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => Validators.validateRequired(value, 'Mother Name'),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Guardian Name
          TextFormField(
            controller: _guardianNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Guardian Name (if different)',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Father Income
          TextFormField(
            controller: _fatherIncomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Father Income (₹)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: Validators.validateIncome,
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Mother Income
          TextFormField(
            controller: _motherIncomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mother Income (₹)',
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: Validators.validateIncome,
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Community
          TextFormField(
            controller: _communityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Community/Caste',
              prefixIcon: Icon(Icons.group),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Academic Information',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // 10th Percentage
          TextFormField(
            controller: _tenthPercentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '10th Standard Percentage',
              prefixIcon: Icon(Icons.school),
              suffixText: '%',
            ),
            validator: Validators.validatePercentage,
          ),
          const SizedBox(height: AppTheme.spacingM),

          // 12th Percentage
          TextFormField(
            controller: _twelfthPercentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '12th Standard Percentage',
              prefixIcon: Icon(Icons.school),
              suffixText: '%',
            ),
            validator: Validators.validatePercentage,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Document Upload',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          Text(
            'Upload your documents. Each file must be under 210 KB.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.lightGrayText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),

          ...DocumentType.values.map((docType) {
            final hasFile = _documentFiles.containsKey(docType) && _documentFiles[docType] != null;
            final isUploading = _documentUploading[docType] == true;
            final isCompressing = _documentCompressing[docType] == true;
            final status = _documentStatus[docType] ?? '';
            
            return Card(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docType.displayName,
                      style: AppTheme.heading3,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    
                    // Status indicator
                    if (status.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status.contains('success') 
                              ? Colors.green.withOpacity(0.1)
                              : status.contains('failed') || status.contains('failed')
                                  ? Colors.red.withOpacity(0.1)
                                  : AppTheme.secondaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCompressing) ...[
                              const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                            ] else if (isUploading) ...[
                              const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                            ] else if (status.contains('success')) ...[
                              const Icon(Icons.check_circle, size: 12, color: Colors.green),
                              const SizedBox(width: AppTheme.spacingS),
                            ] else if (status.contains('failed')) ...[
                              const Icon(Icons.error, size: 12, color: Colors.red),
                              const SizedBox(width: AppTheme.spacingS),
                            ],
                            Text(
                              status,
                              style: AppTheme.bodySmall.copyWith(
                                color: status.contains('success') 
                                    ? Colors.green
                                    : status.contains('failed') 
                                        ? Colors.red
                                        : AppTheme.secondaryGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                    ],
                    
                    if (hasFile) ...[
                      // File preview and info
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              color: AppTheme.secondaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _documentFileNames[docType] ?? 'Unknown file',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.secondaryGold,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    CompressionUtil.formatFileSize(_documentFiles[docType]!.length),
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.secondaryGold.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Preview button for images
                            if (RegExp(r'\.(jpg|jpeg|png)$').hasMatch(
                                (_documentFileNames[docType] ?? '').toLowerCase())) ...[
                              IconButton(
                                onPressed: () => _previewDocument(docType),
                                icon: const Icon(Icons.visibility, size: 18),
                                tooltip: 'Preview',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                    ],
                    
                    // File picker button
                    OutlinedButton.icon(
                      onPressed: (isUploading || isCompressing) ? null : () => _pickDocument(docType),
                      icon: const Icon(Icons.upload_file),
                      label: Text(hasFile ? 'Change File' : 'Select File'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          
          // Upload all button at the bottom
          const SizedBox(height: AppTheme.spacingL),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 32,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Upload All Documents',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Upload all selected documents to secure storage',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.lightGrayText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingM),
                EnhancedButton(
                  text: 'Upload All Documents',
                  onPressed: _isUploadingAll ? null : _uploadAllDocuments,
                  icon: Icons.cloud_upload,
                  isLoading: _isUploadingAll,
                  type: ButtonType.secondary,
                  size: ButtonSize.large,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress Indicator
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    backgroundColor: AppTheme.lightGray.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.lightGrayText,
                  ),
                ),
              ],
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildPersonalInfoPage(),
                _buildFamilyInfoPage(),
                _buildAcademicInfoPage(),
                _buildDocumentsPage(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                if (_currentPage > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage < _totalPages - 1 ? _nextPage : () {
                      print('Save Profile button pressed');
                      _saveProfile();
                    },
                    child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
