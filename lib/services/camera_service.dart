import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  Future<bool> initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return false;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  CameraController? get controller => _controller;

  Future<String?> captureImageAsBase64() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      img.Image resizedImage = img.copyResize(
        decodedImage,
        width: 640,
      );

      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      final base64String = base64Encode(compressedBytes);
      
      await imageFile.delete();
      
      return base64String;
    } catch (e) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
