class ApiConfig {
  static const String baseUrl = 'http://192.168.1.15:3000';
  
  static const String deviceActivate = '/api/devices/activate';
  static const String punchIn = '/api/punch/in';
  static const String punchOut = '/api/punch/out';
  static String userPunchRecords(int userId) => '/api/punch/user/$userId';
  static const String adminLogin = '/api/admin/login';
}
