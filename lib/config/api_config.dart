class ApiConfig {
  // static const String baseUrl = 'https://dev.automica.ai/kiosk-mode';
  static const String baseUrl = 'http://192.168.1.7:4040';
  
  static const String deviceActivate = '/api/devices/activate';
  static const String punchIn = '/api/punch/in';
  static const String punchOut = '/api/punch/out';
  static String userPunchRecords(int userId) => '/api/punch/user/$userId';
  static const String adminLogin = '/api/admin/login';
  
  static const String faceEnroll = '/api/face/enroll';
  static const String faceAttendance = '/api/face/attendance';
  
  static String getUserByEmployeeCode(String employeeCode) => '/api/users/by-employee-code/$employeeCode';
}
