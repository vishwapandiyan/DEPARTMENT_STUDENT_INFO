import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class CompressionUtil {
  static const int maxFileSizeKB = 210;
  static const int maxFileSizeBytes = maxFileSizeKB * 1024;

  /// Compress image file to fit within 210KB limit
  /// Returns compressed bytes or throws exception if compression fails
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Unable to decode image');
      }

      // Start with high quality and reduce until size is acceptable
      int quality = 95;
      int maxWidth = 1600;
      
      while (quality >= 30) {
        // Resize if necessary
        img.Image resizedImage = originalImage;
        if (originalImage.width > maxWidth) {
          resizedImage = img.copyResize(originalImage, width: maxWidth);
        }

        // Compress as JPEG
        final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        
        if (compressedBytes.length <= maxFileSizeBytes) {
          return Uint8List.fromList(compressedBytes);
        }

        // Reduce quality and try again
        quality -= 5;
        if (quality < 40) {
          // If still too large, try reducing width
          maxWidth = (maxWidth * 0.9).round();
          quality = 75;
          
          if (maxWidth < 400) {
            throw Exception(
              'File too large. Please scan with lower quality or resolution. '
              'Current size: ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB'
            );
          }
        }
      }

      throw Exception(
        'Unable to compress file to required size. '
        'Please scan with lower quality or resolution.'
      );
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Validate file size and type
  static bool isValidFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'pdf'].contains(extension);
  }

  /// Check if file type is valid image (JPG, PNG, GIF)
  static bool isValidImageType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }

  /// Check if file size is acceptable
  static bool isAcceptableFileSize(int fileSizeBytes) {
    return fileSizeBytes <= maxFileSizeBytes;
  }

  /// Get file size in KB as string
  static String getFileSizeInKB(int fileSizeBytes) {
    return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get compression tips for user
  static String getCompressionTips() {
    return '''
Compression Tips:
• Use JPEG format for photos
• Scan at 150-300 DPI resolution
• Avoid unnecessary margins
• Use black and white for text documents
• Compress PDFs before scanning if possible
''';
  }
}
