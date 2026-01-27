import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/camera_service.dart';
import '../../services/automica_service.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  final String employeeCode;
  final String employeeName;

  const FaceEnrollmentScreen({
    super.key,
    required this.employeeCode,
    required this.employeeName,
  });

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  final CameraService _cameraService = CameraService();
  final AutomicaService _automicaService = AutomicaService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;

  final List<String> _poses = ['Straight', 'Left', 'Right', 'Smile'];
  int _currentPoseIndex = 0;
  final List<String> _capturedImages = [];

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
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final base64Image = await _cameraService.captureImageAsBase64();
    
    if (base64Image == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to capture image. Please try again.';
      });
      return;
    }

    setState(() {
      _capturedImages.add(base64Image);
      _isProcessing = false;
    });

    if (_currentPoseIndex < _poses.length - 1) {
      setState(() {
        _currentPoseIndex++;
      });
    } else {
      _enrollFace();
    }
  }

  Future<void> _enrollFace() async {
    print('[Face Enrollment] Starting enrollment for ${widget.employeeCode}');
    print('[Face Enrollment] Number of images: ${_capturedImages.length}');
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _automicaService.enrollFace(
        employeeId: widget.employeeCode,
        images: _capturedImages,
        mode: 'replace',
      );

      print('[Face Enrollment] Result: $result');

      if (mounted) {
        if (result['success'] == true) {
          print('[Face Enrollment] Success!');
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Face enrolled successfully for ${widget.employeeName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('[Face Enrollment] Failed: ${result['error']}');
          setState(() {
            _isProcessing = false;
            _errorMessage = result['error'] ?? 'Face enrollment failed';
          });
        }
      }
    } catch (e) {
      print('[Face Enrollment] Exception: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  void _retakeCurrentImage() {
    if (_capturedImages.isNotEmpty) {
      setState(() {
        _capturedImages.removeLast();
        if (_currentPoseIndex > 0) {
          _currentPoseIndex--;
        }
      });
    }
  }

  void _skipEnrollment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Face Enrollment?'),
        content: const Text(
          'The user will be created without face recognition. You can enroll their face later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Skip'),
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
        title: Text('Enroll ${widget.employeeName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _skipEnrollment,
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.white),
            ),
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
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_poses.length, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < _capturedImages.length
                                      ? Colors.green
                                      : index == _currentPoseIndex
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
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
                          'Pose ${_currentPoseIndex + 1} of ${_poses.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Look ${_poses[_currentPoseIndex]}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
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
                        Row(
                          children: [
                            if (_capturedImages.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing ? null : _retakeCurrentImage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retake'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            if (_capturedImages.isNotEmpty) const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _captureImage,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(
                                  _currentPoseIndex == _poses.length - 1
                                      ? 'Finish & Enroll'
                                      : 'Capture',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Make sure you have good lighting and follow the pose instructions',
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
