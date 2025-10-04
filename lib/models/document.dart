import '../constants/enums.dart';

class StudentDocument {
  final String id;
  final String studentId;
  final DocumentType docType;
  final String storagePath;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? fileName;
  final int? fileSize;

  StudentDocument({
    required this.id,
    required this.studentId,
    required this.docType,
    required this.storagePath,
    required this.uploadedBy,
    required this.uploadedAt,
    this.fileName,
    this.fileSize,
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      docType: DocumentType.fromString(json['doc_type'] as String),
      storagePath: json['storage_path'] as String,
      uploadedBy: json['uploaded_by'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'doc_type': docType.value,
      'storage_path': storagePath,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      'file_name': fileName,
      'file_size': fileSize,
    };
  }

  StudentDocument copyWith({
    String? id,
    String? studentId,
    DocumentType? docType,
    String? storagePath,
    String? uploadedBy,
    DateTime? uploadedAt,
    String? fileName,
    int? fileSize,
  }) {
    return StudentDocument(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      docType: docType ?? this.docType,
      storagePath: storagePath ?? this.storagePath,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  // Helper method to get file size in KB
  String get fileSizeInKB {
    if (fileSize == null) return 'Unknown';
    return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
  }

  // Helper method to get file extension from storage path
  String get fileExtension {
    final parts = storagePath.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
