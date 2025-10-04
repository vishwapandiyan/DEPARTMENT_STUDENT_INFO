// Enums for Student Records Webapp

enum StudentClass {
  a('A'),
  b('B'),
  c('C'),
  d('D'),
  e('E');

  const StudentClass(this.value);
  final String value;

  static StudentClass fromString(String value) {
    return StudentClass.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StudentClass.a,
    );
  }
}

enum StudentGender {
  male('male'),
  female('female'),
  other('other');

  const StudentGender(this.value);
  final String value;

  static StudentGender fromString(String value) {
    return StudentGender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StudentGender.male,
    );
  }
}

enum DocumentType {
  aadhaar('aadhaar'),
  birthCert('birth_cert'),
  tenth('10th'),
  twelfth('12th'),
  community('community'),
  income('income');

  const DocumentType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case DocumentType.aadhaar:
        return 'Aadhaar Card';
      case DocumentType.birthCert:
        return 'Birth Certificate';
      case DocumentType.tenth:
        return '10th Mark Sheet';
      case DocumentType.twelfth:
        return '12th Mark Sheet';
      case DocumentType.community:
        return 'Community Certificate';
      case DocumentType.income:
        return 'Income Certificate';
    }
  }

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocumentType.aadhaar,
    );
  }
}
