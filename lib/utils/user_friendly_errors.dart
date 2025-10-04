import 'package:flutter/material.dart';

class UserFriendlyErrors {
  // Authentication Errors
  static const String invalidCredentials = 'Invalid email or password. Please check your credentials and try again.';
  static const String emailAlreadyExists = 'An account with this email already exists. Please use a different email or try signing in.';
  static const String weakPassword = 'Password is too weak. Please use at least 8 characters with a mix of letters, numbers, and symbols.';
  static const String networkError = 'Network connection error. Please check your internet connection and try again.';
  static const String serverError = 'Server is temporarily unavailable. Please try again in a few minutes.';
  static const String unknownAuthError = 'Something went wrong during authentication. Please try again.';

  // Profile Errors
  static const String profileNotFound = 'Profile not found. Please contact support if this issue persists.';
  static const String profileUpdateFailed = 'Failed to update profile. Please check your information and try again.';
  static const String profileLoadFailed = 'Unable to load your profile. Please refresh the page and try again.';

  // Document Upload Errors
  static const String fileTooLarge = 'File size is too large. Please compress your document to under 210 KB and try again.';
  static const String invalidFileType = 'Invalid file type. Please upload only JPG, PNG, or PDF files.';
  static const String uploadFailed = 'Failed to upload document. Please check your internet connection and try again.';
  static const String compressionFailed = 'Unable to compress your file. Please try with a smaller file or lower quality.';
  static const String storageError = 'Unable to save your document. Please try again or contact support.';

  // Student Data Errors
  static const String studentNotFound = 'Student record not found. Please contact your administrator.';
  static const String studentSaveFailed = 'Failed to save student information. Please check your details and try again.';
  static const String studentLoadFailed = 'Unable to load student data. Please refresh and try again.';

  // CSV Export Errors
  static const String csvExportFailed = 'Failed to export data. Please try again or contact support.';
  static const String csvDownloadFailed = 'Unable to download file. Please check your browser settings and try again.';

  // General Errors
  static const String unexpectedError = 'Something unexpected happened. Please try again or contact support if the issue persists.';
  static const String permissionDenied = 'You do not have permission to perform this action. Please contact your administrator.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String maintenanceMode = 'The system is currently under maintenance. Please try again later.';

  /// Convert technical error messages to user-friendly ones
  static String getFriendlyError(String? technicalError) {
    if (technicalError == null || technicalError.isEmpty) {
      return unexpectedError;
    }

    final error = technicalError.toLowerCase();

    // Authentication errors
    if (error.contains('invalid_credentials') || error.contains('wrong password')) {
      return invalidCredentials;
    }
    if (error.contains('email_already_registered') || error.contains('user already registered')) {
      return emailAlreadyExists;
    }
    if (error.contains('password_too_weak') || error.contains('password is too weak')) {
      return weakPassword;
    }
    if (error.contains('network') || error.contains('connection') || error.contains('timeout')) {
      return networkError;
    }
    if (error.contains('server') || error.contains('500') || error.contains('internal server')) {
      return serverError;
    }

    // File upload errors
    if (error.contains('file too large') || error.contains('size limit')) {
      return fileTooLarge;
    }
    if (error.contains('invalid file') || error.contains('unsupported format')) {
      return invalidFileType;
    }
    if (error.contains('upload failed') || error.contains('storage error')) {
      return uploadFailed;
    }
    if (error.contains('compression') || error.contains('compress')) {
      return compressionFailed;
    }

    // Database errors
    if (error.contains('not found') || error.contains('does not exist')) {
      return studentNotFound;
    }
    if (error.contains('permission denied') || error.contains('unauthorized')) {
      return permissionDenied;
    }
    if (error.contains('session') || error.contains('token')) {
      return sessionExpired;
    }

    // Default fallback
    return unexpectedError;
  }

  /// Show a user-friendly error snackbar
  static void showErrorSnackBar(BuildContext context, String? technicalError) {
    final friendlyMessage = getFriendlyError(technicalError);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyMessage),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a user-friendly error dialog
  static void showErrorDialog(BuildContext context, String? technicalError, {String? title}) {
    final friendlyMessage = getFriendlyError(technicalError);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(title ?? 'Error'),
          ],
        ),
        content: Text(friendlyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a success message
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
