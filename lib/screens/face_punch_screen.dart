import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/automica_service.dart';
import '../services/api_service.dart';
import 'admin/admin_login_screen.dart';

class FacePunchScreen extends StatefulWidget {
  const FacePunchScreen({super.key});

  @override
  State<FacePunchScreen> createState() => _FacePunchScreenState();
}

class _FacePunchScreenState extends State<FacePunchScreen> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final AutomicaService _automicaService = AutomicaService();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _lastPunchData;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initializeCamera();
    if (success) {
      setState(() {
        _isInitialized = true;
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to initialize camera. Please check permissions.';
      });
    }
  }

  Future<void> _handlePunch(String event) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final location = await _locationService.getCurrentLocation();
    if (location == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get GPS location. Please enable location services.';
      });
      return;
    }

    final base64Image = await _cameraService.captureImageAsBase64();
    if (base64Image == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to capture image. Please try again.';
      });
      return;
    }

    final attendanceResult = await _automicaService.markAttendance(
      base64Image: base64Image,
      gpsLat: location['latitude']!,
      gpsLng: location['longitude']!,
      event: event,
    );

    if (!attendanceResult['success']) {
      String errorMessage = attendanceResult['error'] ?? 'Face recognition failed';
      
      // If we have details (like from Automica API), use them for better UX
      if (attendanceResult['details'] != null && attendanceResult['details'].isNotEmpty) {
        if (attendanceResult['details'] is List) {
          errorMessage = (attendanceResult['details'] as List).join(', ');
        } else if (attendanceResult['details'] is String) {
          errorMessage = attendanceResult['details'];
        }
      } else if (attendanceResult['reason_code'] != null) {
        // Fallback for common reason codes if message is generic
        final reason = attendanceResult['reason_code'].toString().toLowerCase();
        if (reason.contains('quality')) {
          errorMessage = 'Low Quality Image';
        } else if (reason.contains('dark')) {
          errorMessage = 'Image too dark';
        }
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
      return;
    }

    final employeeId = attendanceResult['employee_id'];
    
    final userId = await _getUserIdFromEmployeeCode(employeeId);
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Employee not found in system';
      });
      return;
    }

    final punchResult = event == 'in'
        ? await _apiService.punchIn(userId)
        : await _apiService.punchOut(userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (punchResult['success']) {
        setState(() {
          _successMessage = punchResult['message'];
          _lastPunchData = {
            'employee': punchResult['user']?.name ?? 'Unknown',
            'employeeCode': employeeId,
            'event': event,
            'matchScore': attendanceResult['match_score'],
            'quality': attendanceResult['quality'],
            'time': DateTime.now(),
          };
        });
        _showSuccessDialog(event);
      } else {
        setState(() {
          _errorMessage = punchResult['error'] ?? 'Punch operation failed';
        });
      }
    }
  }

  Future<int?> _getUserIdFromEmployeeCode(String employeeCode) async {
    try {
      final response = await _apiService.getUserByEmployeeCode(employeeCode);
      if (response['success']) {
        return response['user'].id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showSuccessDialog(String event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              event == 'in' ? Icons.login : Icons.logout,
              color: event == 'in' ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text('Punch ${event == 'in' ? 'In' : 'Out'} Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee: ${_lastPunchData?['employee'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Employee ID: ${_lastPunchData?['employeeCode'] ?? 'N/A'}'),
            Text('Match Score: ${(_lastPunchData?['match_score'] ?? 0).toStringAsFixed(2)}'),
            if (_lastPunchData?['quality'] != null)
              Text('Image Quality: ${_lastPunchData?['quality']['face_quality'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Punch'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'admin') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminLoginScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Admin Panel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraService.controller!.value.previewSize!.height,
                            height: _cameraService.controller!.value.previewSize!.width,
                            child: CameraPreview(_cameraService.controller!),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 250,
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(150),
                          ),
                        ),
                      ),
                      if (_isLoading)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey[100],
                    child: Column(
                      children: [
                        const Text(
                          'Position your face in the frame',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recognition Failed',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_successMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _handlePunch('in'),
                                  icon: const Icon(Icons.login),
                                  label: const Text(
                                    'Punch In',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _handlePunch('out'),
                                  icon: const Icon(Icons.logout),
                                  label: const Text(
                                    'Punch Out',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Make sure you have good lighting and look directly at the camera',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: _errorMessage != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initializeCamera,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
    );
  }
}
