import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/admin.dart';
import '../models/user.dart';
import '../models/device.dart';

class AdminApiService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminLogin}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'token': data['token'],
            'admin': Admin.fromJson(data['admin']),
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Response parsing error: $parseError. Response: ${response.body}',
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? 'Login failed',
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Server error (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAllUsers(String token, {int page = 1, int limit = 10, String? status}) async {
    try {
      String url = '${ApiConfig.baseUrl}/api/users?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'users': (data['users'] as List?)
                ?.map((u) => User.fromJson(u as Map<String, dynamic>))
                .toList() ?? [],
            'total': data['total'] as int? ?? 0,
            'page': data['page'] as int? ?? 1,
            'limit': data['limit'] as int? ?? 10,
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Response parsing error: $parseError. Response: ${response.body}',
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? 'Failed to fetch users',
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Server error (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createUser(String token, Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to create user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAllDevices(String token, {int page = 1, int limit = 10, bool? isActive}) async {
    try {
      String url = '${ApiConfig.baseUrl}/api/devices?page=$page&limit=$limit';
      if (isActive != null) {
        url += '&isActive=$isActive';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'devices': (data['devices'] as List?)
                ?.map((d) => Device.fromJson(d as Map<String, dynamic>))
                .toList() ?? [],
            'total': data['total'] as int? ?? 0,
            'page': data['page'] as int? ?? 1,
            'limit': data['limit'] as int? ?? 10,
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Response parsing error: $parseError. Response: ${response.body}',
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? 'Failed to fetch devices',
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Server error (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> generateActivationCode(String token, int deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/devices/$deviceId/generate-code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'activationCode': data['activationCode'] as String?,
            'message': data['message'],
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Response parsing error: $parseError',
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? 'Failed to generate activation code',
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Server error (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createDevice(String token, Map<String, dynamic> deviceData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(deviceData),
      );

      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'device': Device.fromJson(data['device']),
            'activationCode': data['activationCode'] as String?,
            'message': data['message'],
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Response parsing error: $parseError',
          };
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? 'Failed to create device',
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Server error (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
