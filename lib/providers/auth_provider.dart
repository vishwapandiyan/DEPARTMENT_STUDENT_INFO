import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../controllers/auth_controller.dart';
import '../utils/compress_util.dart';
import '../utils/user_friendly_errors.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _authController = AuthController();

  User? _user;
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isStaff => _profile?.isStaff ?? false;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _user = _authController.currentUser;
    if (_user != null) {
      _loadProfile();
    }

    // Listen to auth state changes
    _authController.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          _user = session?.user;
          _loadProfile();
          break;
        case AuthChangeEvent.signedOut:
          _user = null;
          _profile = null;
          break;
        case AuthChangeEvent.userUpdated:
          _user = session?.user;
          break;
        case AuthChangeEvent.passwordRecovery:
          // Handle password recovery
          break;
        case AuthChangeEvent.tokenRefreshed:
          _user = session?.user;
          break;
        default:
          break;
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;

    try {
      _profile = await _authController.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: $e';
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String enrollmentNo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if enrollment number is already taken
      final isTaken = await _authController.isEnrollmentNumberTaken(enrollmentNo);
      if (isTaken) {
        _error = 'Enrollment number is already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _authController.signUp(
        email: email,
        password: password,
        fullName: fullName,
        enrollmentNo: enrollmentNo,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign up failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authController.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign in failed. Please check your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authController.signOut();
      _user = null;
      _profile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authController.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? enrollmentNo,
    bool? isStaff,
    String? studentClass,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authController.updateProfile(
        userId: _user!.id,
        fullName: fullName,
        enrollmentNo: enrollmentNo,
        isStaff: isStaff,
        studentClass: studentClass,
      );

      await _loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload profile photo
  Future<bool> uploadProfilePhoto({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (_user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate file type
      if (!CompressionUtil.isValidImageType(fileName)) {
        _error = 'Invalid file type. Please upload JPG, PNG, or GIF files only.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Compress image if it's too large
      Uint8List compressedBytes = fileBytes;
      if (fileBytes.length > CompressionUtil.maxFileSizeBytes) {
        compressedBytes = await CompressionUtil.compressImage(fileBytes);
      }

      // Check final file size
      if (!CompressionUtil.isAcceptableFileSize(compressedBytes.length)) {
        _error = 'File size too large. ${CompressionUtil.getCompressionTips()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Upload photo
      final storagePath = await _authController.uploadProfilePhoto(
        userId: _user!.id,
        fileBytes: compressedBytes,
        fileName: fileName,
      );

      // Update profile with photo path
      await _authController.updateProfilePhotoPath(_user!.id, storagePath);

      // Reload profile
      await _loadProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get profile photo download URL
  Future<String?> getProfilePhotoDownloadUrl() async {
    if (_profile?.profilePhotoPath == null) return null;
    
    try {
      return await _authController.getProfilePhotoDownloadUrl(_profile!.profilePhotoPath!);
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    if (_user == null || _profile?.profilePhotoPath == null) {
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authController.deleteProfilePhoto(_user!.id, _profile!.profilePhotoPath!);
      await _loadProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = UserFriendlyErrors.getFriendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
