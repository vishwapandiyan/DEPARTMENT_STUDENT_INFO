import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/enums.dart';

class Profile {
  final String id;
  final String fullName;
  final String enrollmentNo;
  final bool isStaff;
  final StudentClass? studentClass;
  final String? profilePhotoPath;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.enrollmentNo,
    required this.isStaff,
    this.studentClass,
    this.profilePhotoPath,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      enrollmentNo: json['enrollment_no'] as String,
      isStaff: json['is_staff'] as bool? ?? false,
      studentClass: json['class'] != null 
          ? StudentClass.fromString(json['class'] as String)
          : null,
      profilePhotoPath: json['profile_photo_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'enrollment_no': enrollmentNo,
      'is_staff': isStaff,
      'class': studentClass?.value,
      'profile_photo_path': profilePhotoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? enrollmentNo,
    bool? isStaff,
    StudentClass? studentClass,
    String? profilePhotoPath,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      isStaff: isStaff ?? this.isStaff,
      studentClass: studentClass ?? this.studentClass,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
