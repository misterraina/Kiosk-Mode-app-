class User {
  final int id;
  final String employeeCode;
  final String name;
  final String status;
  final String? faceProfileId;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.status,
    this.faceProfileId,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      employeeCode: json['employeeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'UNKNOWN',
      faceProfileId: json['faceProfileId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'name': name,
      'status': status,
      'faceProfileId': faceProfileId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'ACTIVE';
}
