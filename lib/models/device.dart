class Device {
  final int id;
  final String deviceCode;
  final String location;
  final bool isActive;
  final DateTime? lastSeenAt;

  Device({
    required this.id,
    required this.deviceCode,
    required this.location,
    required this.isActive,
    this.lastSeenAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int? ?? 0,
      deviceCode: (json['deviceCode'] ?? json['devicecode']) as String? ?? '',
      location: json['location'] as String? ?? '',
      isActive: (json['isActive'] ?? json['isactive']) as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceCode': deviceCode,
      'location': location,
      'isActive': isActive,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }
}
