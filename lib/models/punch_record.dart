class PunchRecord {
  final int id;
  final int userId;
  final int deviceId;
  final DateTime punchInAt;
  final DateTime? punchOutAt;
  final int? durationMinutes;
  final String status;
  final DateTime? createdAt;
  final String? userName;
  final String? employeeCode;
  final String? deviceCode;
  final String? location;

  PunchRecord({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.punchInAt,
    this.punchOutAt,
    this.durationMinutes,
    required this.status,
    this.createdAt,
    this.userName,
    this.employeeCode,
    this.deviceCode,
    this.location,
  });

  factory PunchRecord.fromJson(Map<String, dynamic> json) {
    return PunchRecord(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      deviceId: json['deviceId'] as int? ?? 0,
      punchInAt: DateTime.parse(json['punchInAt'] as String? ?? DateTime.now().toIso8601String()),
      punchOutAt: json['punchOutAt'] != null
          ? DateTime.parse(json['punchOutAt'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      status: json['status'] as String? ?? 'UNKNOWN',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      userName: json['userName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      deviceCode: json['deviceCode'] as String?,
      location: json['location'] as String?,
    );
  }

  bool get isOpen => status == 'OPEN';
  bool get isClosed => status == 'CLOSED';
}
