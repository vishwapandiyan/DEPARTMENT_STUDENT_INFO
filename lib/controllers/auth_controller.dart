import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String enrollmentNo,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'enrollment_no': enrollmentNo,
        },
      );

      if (response.user != null) {
        // Wait a moment for auth state to be established
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Create profile record using secure database function
        await _createProfile(
          userId: response.user!.id,
          fullName: fullName,
          enrollmentNo: enrollmentNo,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile
  Future<Profile?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? enrollmentNo,
    bool? isStaff,
    String? studentClass,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (enrollmentNo != null) updateData['enrollment_no'] = enrollmentNo;
      if (isStaff != null) updateData['is_staff'] = isStaff;
      if (studentClass != null) updateData['class'] = studentClass;

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Create profile record for new user
  Future<void> _createProfile({
    required String userId,
    required String fullName,
    required String enrollmentNo,
  }) async {
    try {
      // Use the database function to create profile (bypasses RLS)
      await _supabase.rpc('create_user_profile', params: {
        'user_id': userId,
        'full_name': fullName,
        'enrollment_no': enrollmentNo,
      });
    } catch (e) {
      print('Error creating profile: $e');
      rethrow;
    }
  }

  /// Create staff profile (for admin use)
  Future<void> createStaffProfile({
    required String userId,
    required String fullName,
    required String enrollmentNo,
    required String studentClass,
  }) async {
    try {
      await _supabase.rpc('create_staff_profile', params: {
        'user_id': userId,
        'full_name': fullName,
        'enrollment_no': enrollmentNo,
        'student_class': studentClass,
      });
    } catch (e) {
      print('Error creating staff profile: $e');
      rethrow;
    }
  }

  /// Check if enrollment number already exists
  Future<bool> isEnrollmentNumberTaken(String enrollmentNo) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('enrollment_no')
          .eq('enrollment_no', enrollmentNo)
          .maybeSingle();

      return response != null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final storagePath = 'profile-photos/$userId/${timestamp}_$fileName';
      
      // Upload to storage
      await _supabase.storage
          .from('student-docs') // Using same bucket as documents
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      return storagePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Update profile photo path in database
  Future<void> updateProfilePhotoPath(String userId, String photoPath) async {
    try {
      await _supabase
          .from('profiles')
          .update({'profile_photo_path': photoPath})
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile photo download URL
  Future<String> getProfilePhotoDownloadUrl(String storagePath) async {
    try {
      final response = await _supabase.storage
          .from('student-docs')
          .createSignedUrl(storagePath, 3600); // 1 hour expiry

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId, String storagePath) async {
    try {
      // Delete from storage
      await _supabase.storage
          .from('student-docs')
          .remove([storagePath]);

      // Update database to remove photo path
      await _supabase
          .from('profiles')
          .update({'profile_photo_path': null})
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
