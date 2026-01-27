import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/automica_service.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const FaceEnrollmentScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final AutomicaService _automicaService = AutomicaService();

  bool _isInitialized = false;
  bool _isLoading = false;
  List<String> _capturedImages = [];
  final int _requiredImages = 4;
  String? _errorMessage;

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

  Future<void> _captureImage() async {
    if (_capturedImages.length >= _requiredImages) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final base64Image = await _cameraService.captureImageAsBase64();

    if (base64Image != null) {
      setState(() {
        _capturedImages.add(base64Image);
        _isLoading = false;
      });

      if (_capturedImages.length >= _requiredImages) {
        _showEnrollConfirmation();
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to capture image. Please try again.';
      });
    }
  }

  void _showEnrollConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ready to Enroll'),
        content: Text(
          'You have captured ${_capturedImages.length} images. Do you want to proceed with enrollment?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImages.clear();
              });
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enrollEmployee();
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollEmployee() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _automicaService.enrollEmployee(
      employeeId: widget.employeeId,
      base64Images: _capturedImages,
      mode: 'replace',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Enrollment failed';
        });
        _showErrorDialog(result['error'] ?? 'Enrollment failed');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Enrollment Successful'),
          ],
        ),
        content: Text(
          '${widget.employeeName} has been successfully enrolled for face recognition.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Enrollment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImages.clear();
              });
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
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
        title: const Text('Face Enrollment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _cameraService.controller!.value.aspectRatio,
                          child: CameraPreview(_cameraService.controller!),
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
                        Text(
                          widget.employeeName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Employee ID: ${widget.employeeId}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Images Captured: ${_capturedImages.length}/$_requiredImages',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _capturedImages.length / _requiredImages,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || _capturedImages.length >= _requiredImages
                                ? null
                                : _captureImage,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: Text(
                              _isLoading
                                  ? 'Processing...'
                                  : _capturedImages.length >= _requiredImages
                                      ? 'All Images Captured'
                                      : 'Capture Image',
                              style: const TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_capturedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _capturedImages.clear();
                                      _errorMessage = null;
                                    });
                                  },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset and Start Over'),
                          ),
                        ],
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
