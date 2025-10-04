import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../../constants/theme.dart';
import '../../constants/enums.dart';
import '../../models/document.dart';
import '../../providers/student_provider.dart';

class DocumentPreviewDialog extends StatefulWidget {
  final StudentDocument document;

  const DocumentPreviewDialog({
    super.key,
    required this.document,
  });

  @override
  State<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends State<DocumentPreviewDialog> {
  String? _previewUrl;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreviewUrl();
  }

  Future<void> _loadPreviewUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For now, we'll use the download URL as preview URL
      // In a real implementation, you might want separate preview URLs
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final url = await studentProvider.getDocumentDownloadUrlForStaff(widget.document.storagePath);
      
      setState(() {
        _previewUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDocumentIcon(widget.document.docType),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.docType.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.document.fileName != null)
                          Text(
                            widget.document.fileName!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _buildPreviewContent(),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Uploaded: ${widget.document.uploadedAt.toLocal().toString().split(' ')[0]} • ${widget.document.fileSizeInKB}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.lightGrayText,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _downloadDocument,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              'Failed to load preview',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.lightGrayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPreviewUrl,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_previewUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 64,
                    color: AppTheme.lightGrayText,
            ),
            const SizedBox(height: 16),
            Text(
              'Preview not available',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.lightGrayText,
              ),
            ),
          ],
        ),
      );
    }

    // Check if it's an image file
    final fileName = widget.document.fileName?.toLowerCase() ?? '';
    final isImage = fileName.endsWith('.jpg') || 
                   fileName.endsWith('.jpeg') || 
                   fileName.endsWith('.png') || 
                   fileName.endsWith('.gif');

    if (isImage) {
      return _buildImagePreview();
    } else {
      return _buildDocumentInfo();
    }
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: InteractiveViewer(
          child: Image.network(
            _previewUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadPreviewUrl,
                    child: const Text('Retry'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDocumentIcon(widget.document.docType),
            size: 80,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 24),
          Text(
            widget.document.docType.displayName,
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (widget.document.fileName != null) ...[
            Text(
              widget.document.fileName!,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.lightGrayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Document Preview',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This document type cannot be previewed in the browser. Please download to view.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.lightGrayText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _downloadDocument,
            icon: const Icon(Icons.download),
            label: const Text('Download Document'),
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

  Future<void> _downloadDocument() async {
    try {
      if (_previewUrl != null && kIsWeb) {
        html.window.open(_previewUrl!, '_blank');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${widget.document.docType.displayName}...'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
