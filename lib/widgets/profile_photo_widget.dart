import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/auth_provider.dart';

class ProfilePhotoWidget extends StatefulWidget {
  final double size;
  final bool showEditButton;
  final VoidCallback? onPhotoChanged;

  const ProfilePhotoWidget({
    super.key,
    this.size = 120,
    this.showEditButton = true,
    this.onPhotoChanged,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.profile?.profilePhotoPath != null) {
      try {
        final url = await authProvider.getProfilePhotoDownloadUrl();
        if (mounted) {
          setState(() {
            _photoUrl = url;
          });
        }
      } catch (e) {
        print('Failed to load profile photo: $e');
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _isLoading = true;
          });

          final success = await authProvider.uploadProfilePhoto(
            fileBytes: file.bytes!,
            fileName: file.name,
          );

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            if (success) {
              await _loadProfilePhoto();
              widget.onPhotoChanged?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile photo updated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.error ?? 'Failed to update profile photo'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile Photo'),
        content: const Text('Are you sure you want to delete your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await authProvider.deleteProfilePhoto();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _photoUrl = null;
        });

        if (success) {
          widget.onPhotoChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo deleted successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to delete profile photo'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: widget.size + 30, // Extra space for edit button
          height: widget.size + 30, // Extra space for edit button
          child: Stack(
            clipBehavior: Clip.none, // Allow overflow
            children: [
              // Profile Photo Circle
              Positioned(
                top: 15,
                left: 15,
                child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBlue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mediumGray.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                  child: ClipOval(
                    child: _isLoading
                        ? Container(
                            color: AppTheme.lightGray.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          )
                        : _photoUrl != null
                            ? Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar();
                                },
                              )
                            : _buildDefaultAvatar(),
                  ),
                ),
              ),

              // Edit Button
              if (widget.showEditButton && !_isLoading)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      iconSize: 28,
                      onSelected: (value) {
                        switch (value) {
                          case 'change':
                            _pickAndUploadPhoto();
                            break;
                          case 'delete':
                            if (_photoUrl != null) {
                              _deletePhoto();
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'change',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Change Photo'),
                            ],
                          ),
                        ),
                        if (_photoUrl != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                                SizedBox(width: 8),
                                Text('Delete Photo', style: TextStyle(color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.lightGray.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: AppTheme.lightGray,
      ),
    );
  }
}
