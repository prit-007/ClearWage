class EmployeeDocument {
  final String id;
  final String docType;
  final String filePath;
  final String? publicId;
  final String? originalName;
  final DateTime? uploadedAt;

  EmployeeDocument({
    required this.id,
    required this.docType,
    required this.filePath,
    this.publicId,
    this.originalName,
    this.uploadedAt,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) =>
      EmployeeDocument(
        id: json['id'] as String? ?? '',
        docType: json['doc_type'] as String? ?? '',
        filePath: json['file_path'] as String? ?? '',
        publicId: json['public_id'] as String?,
        originalName: json['original_name'] as String?,
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.tryParse(json['uploaded_at'] as String)
            : null,
      );

  bool get isPdf =>
      filePath.toLowerCase().endsWith('.pdf') ||
      (originalName?.toLowerCase().endsWith('.pdf') ?? false);

  Map<String, dynamic> toJson() => {
    'id': id,
    'doc_type': docType,
    'file_path': filePath,
    'public_id': publicId,
    'original_name': originalName,
    'uploaded_at': uploadedAt?.toIso8601String(),
  };
}
