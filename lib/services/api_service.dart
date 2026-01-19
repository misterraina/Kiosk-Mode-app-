import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/device.dart';
import '../models/user.dart';
import '../models/punch_record.dart';

class ApiService {
  Future<Map<String, dynamic>> activateDevice(String deviceCode, String adminToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deviceActivate}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({'deviceCode': deviceCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'deviceToken': data['deviceToken'],
          'device': Device.fromJson(data['device']),
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to activate device',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> activateDeviceWithCode(String activationCode) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/devices/activate-with-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'activationCode': activationCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'deviceToken': data['deviceToken'],
          'device': Device.fromJson(data['device']),
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to activate device',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> punchIn(int userId, String deviceToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.punchIn}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Token': deviceToken,
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        try {
          return {
            'success': true,
            'message': data['message'],
            'punchRecord': PunchRecord.fromJson(data['punchRecord']),
            'user': User.fromJson(data['user']),
            'device': Device.fromJson(data['device']),
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Data parsing error: $parseError',
          };
        }
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to punch in',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> punchOut(int userId, String deviceToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.punchOut}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Token': deviceToken,
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          return {
            'success': true,
            'message': data['message'],
            'punchRecord': PunchRecord.fromJson(data['punchRecord']),
            'device': Device.fromJson(data['device']),
          };
        } catch (parseError) {
          return {
            'success': false,
            'error': 'Data parsing error: $parseError',
          };
        }
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to punch out',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getUserPunchRecords(int userId, {int page = 1, int limit = 10, String? status}) async {
    try {
      String url = '${ApiConfig.baseUrl}${ApiConfig.userPunchRecords(userId)}?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'punchRecords': (data['punchRecords'] as List)
              .map((record) => PunchRecord.fromJson(record))
              .toList(),
          'total': data['total'],
          'page': data['page'],
          'limit': data['limit'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to fetch punch records',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
