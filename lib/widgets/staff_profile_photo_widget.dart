import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../constants/theme.dart';
import '../models/profile.dart';
import '../controllers/auth_controller.dart';

class StaffProfilePhotoWidget extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final double size;
  final bool showDownloadButton;

  const StaffProfilePhotoWidget({
    super.key,
    required this.profileData,
    this.size = 60,
    this.showDownloadButton = false,
  });

  @override
  State<StaffProfilePhotoWidget> createState() => _StaffProfilePhotoWidgetState();
}

class _StaffProfilePhotoWidgetState extends State<StaffProfilePhotoWidget> {
  String? _photoUrl;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  @override
  void didUpdateWidget(StaffProfilePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPath = oldWidget.profileData?['profile_photo_path'];
    final newPath = widget.profileData?['profile_photo_path'];
    if (oldPath != newPath) {
      _loadProfilePhoto();
    }
  }

  Future<void> _loadProfilePhoto() async {
    final photoPath = widget.profileData?['profile_photo_path'] as String?;
    if (photoPath == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final authController = AuthController();
      final url = await authController.getProfilePhotoDownloadUrl(photoPath);
      
      if (mounted) {
        setState(() {
          _photoUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPhoto() async {
    if (_photoUrl == null) return;

    try {
      if (kIsWeb) {
        html.window.open(_photoUrl!, '_blank');
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 30, // Extra space for buttons
      height: widget.size + 30, // Extra space for buttons
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow
        children: [
          // Main profile photo container
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
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mediumGray.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildPhotoContent(),
              ),
            ),
          ),

          // Action buttons - positioned outside the circle
          if (_photoUrl != null)
            Positioned(
              bottom: 5,
              right: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View button
                  GestureDetector(
                    onTap: () => _showPhotoDialog(context),
                    child: Container(
                      width: 28,
                      height: 28,
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
                      child: const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                    if (widget.showDownloadButton) ...[
                      const SizedBox(width: 6),
                      // Download button
                      GestureDetector(
                        onTap: _downloadPhoto,
                        child: Container(
                          width: 28,
                          height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGold,
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
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (_isLoading) {
      return Container(
        color: AppTheme.lightGray.withOpacity(0.1),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      );
    } else if (_hasError) {
      return Container(
        color: AppTheme.lightGray.withOpacity(0.1),
        child: Icon(
          Icons.error_outline,
          size: widget.size * 0.4,
          color: AppTheme.errorColor,
        ),
      );
    } else if (_photoUrl != null) {
      return GestureDetector(
        onTap: () => _showPhotoDialog(context),
        child: Image.network(
          _photoUrl!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  void _showPhotoDialog(BuildContext context) {
    if (_photoUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Full-screen photo viewer
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  _photoUrl!,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            // Download button
            Positioned(
              top: 40,
              left: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _downloadPhoto();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
