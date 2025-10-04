import '../constants/enums.dart';

class Student {
  final String id;
  final String profileId;
  final String? aadhaar;
  final DateTime? dob;
  final String? address;
  final String? guardianName;
  final String? motherName;
  final String? fatherName;
  final bool siblings;
  final String? community;
  final double? tenthPercent;
  final double? twelfthPercent;
  final double? fatherIncome;
  final double? motherIncome;
  final StudentGender gender;
  final StudentClass studentClass;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.profileId,
    this.aadhaar,
    this.dob,
    this.address,
    this.guardianName,
    this.motherName,
    this.fatherName,
    required this.siblings,
    this.community,
    this.tenthPercent,
    this.twelfthPercent,
    this.fatherIncome,
    this.motherIncome,
    required this.gender,
    required this.studentClass,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      aadhaar: json['aadhaar'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      address: json['address'] as String?,
      guardianName: json['guardian_name'] as String?,
      motherName: json['mother_name'] as String?,
      fatherName: json['father_name'] as String?,
      siblings: json['siblings'] as bool? ?? false,
      community: json['community'] as String?,
      tenthPercent: json['tenth_percent'] != null 
          ? (json['tenth_percent'] as num).toDouble() 
          : null,
      twelfthPercent: json['twelfth_percent'] != null 
          ? (json['twelfth_percent'] as num).toDouble() 
          : null,
      fatherIncome: json['father_income'] != null 
          ? (json['father_income'] as num).toDouble() 
          : null,
      motherIncome: json['mother_income'] != null 
          ? (json['mother_income'] as num).toDouble() 
          : null,
      gender: StudentGender.fromString(json['gender'] as String? ?? 'male'),
      studentClass: StudentClass.fromString(json['class'] as String? ?? 'A'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'profile_id': profileId,
      'aadhaar': aadhaar,
      'dob': dob?.toIso8601String().split('T')[0], // Date only
      'address': address,
      'guardian_name': guardianName,
      'mother_name': motherName,
      'father_name': fatherName,
      'siblings': siblings,
      'community': community,
      'tenth_percent': tenthPercent,
      'twelfth_percent': twelfthPercent,
      'father_income': fatherIncome,
      'mother_income': motherIncome,
      'gender': gender.value,
      'class': studentClass.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }

  Student copyWith({
    String? id,
    String? profileId,
    String? aadhaar,
    DateTime? dob,
    String? address,
    String? guardianName,
    String? motherName,
    String? fatherName,
    bool? siblings,
    String? community,
    double? tenthPercent,
    double? twelfthPercent,
    double? fatherIncome,
    double? motherIncome,
    StudentGender? gender,
    StudentClass? studentClass,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      aadhaar: aadhaar ?? this.aadhaar,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      guardianName: guardianName ?? this.guardianName,
      motherName: motherName ?? this.motherName,
      fatherName: fatherName ?? this.fatherName,
      siblings: siblings ?? this.siblings,
      community: community ?? this.community,
      tenthPercent: tenthPercent ?? this.tenthPercent,
      twelfthPercent: twelfthPercent ?? this.twelfthPercent,
      fatherIncome: fatherIncome ?? this.fatherIncome,
      motherIncome: motherIncome ?? this.motherIncome,
      gender: gender ?? this.gender,
      studentClass: studentClass ?? this.studentClass,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get masked Aadhaar for display
  String get maskedAadhaar {
    if (aadhaar == null || aadhaar!.isEmpty) return 'Not provided';
    if (aadhaar!.length < 4) return 'Invalid format';
    return '****-****-${aadhaar!.substring(aadhaar!.length - 4)}';
  }

  // Helper method to check if student profile is complete
  bool get isProfileComplete {
    return aadhaar != null &&
        aadhaar!.isNotEmpty &&
        dob != null &&
        address != null &&
        address!.isNotEmpty &&
        fatherName != null &&
        fatherName!.isNotEmpty &&
        motherName != null &&
        motherName!.isNotEmpty;
  }
}
