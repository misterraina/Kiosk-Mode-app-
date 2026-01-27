import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AutomicaService {
  Future<Map<String, dynamic>> enrollFace({
    required String employeeId,
    required List<String> images,
    String mode = 'replace',
  }) async {
    return enrollEmployee(
      employeeId: employeeId,
      base64Images: images,
      mode: mode,
    );
  }

  Future<Map<String, dynamic>> enrollEmployee({
    required String employeeId,
    required List<String> base64Images,
    required String mode,
  }) async {
    try {
      print('[AutomicaService] Enrolling employee: $employeeId');
      print('[AutomicaService] Number of images: ${base64Images.length}');
      print('[AutomicaService] URL: ${ApiConfig.baseUrl}${ApiConfig.faceEnroll}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.faceEnroll}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'employee_id': employeeId,
          'mode': mode,
          'images': base64Images,
        }),
      );

      print('[AutomicaService] Response status: ${response.statusCode}');
      print('[AutomicaService] Response body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response from server',
        };
      }

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (e) {
        return {
          'success': false,
          'error': 'Invalid JSON response: ${response.body}',
        };
      }

      if (data == null) {
        return {
          'success': false,
          'error': 'Null response from server',
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Enrollment successful',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? data['message'] ?? 'Enrollment failed',
          'reason_code': data['reason_code'],
          'details': data['details'],
        };
      }
    } catch (e) {
      print('[AutomicaService] Exception: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> markAttendance({
    required String base64Image,
    required String gpsLat,
    required String gpsLng,
    required String event,
    String? employeeId,
  }) async {
    try {
      final body = {
        'image': base64Image,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'event': event,
      };

      if (employeeId != null) {
        body['employee_id'] = employeeId;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.faceAttendance}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'employee_id': data['employee_id'],
          'decision': data['decision'],
          'match_score': data['match_score'],
          'quality': data['quality'],
          'message': 'Attendance marked successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Attendance marking failed',
          'reason_code': data['reason_code'],
          'details': data['details'],
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
