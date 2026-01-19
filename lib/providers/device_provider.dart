import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DeviceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Device? _device;
  String? _deviceToken;
  bool _isActivated = false;
  bool _isLoading = false;
  String? _error;

  Device? get device => _device;
  String? get deviceToken => _deviceToken;
  bool get isActivated => _isActivated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;

    _deviceToken = await _storageService.getDeviceToken();
    final deviceInfo = await _storageService.getDeviceInfo();

    if (_deviceToken != null && deviceInfo != null) {
      _device = Device(
        id: deviceInfo['id'],
        deviceCode: deviceInfo['code'],
        location: deviceInfo['location'],
        isActive: true,
      );
      _isActivated = true;
    }

    _isLoading = false;
  }

  Future<bool> activateDevice(String deviceCode, String adminToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.activateDevice(deviceCode, adminToken);

    if (result['success']) {
      _deviceToken = result['deviceToken'];
      _device = result['device'];
      _isActivated = true;

      await _storageService.saveDeviceToken(_deviceToken!);
      await _storageService.saveDeviceInfo(
        _device!.id,
        _device!.deviceCode,
        _device!.location,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateDeviceWithCode(String activationCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.activateDeviceWithCode(activationCode);

    if (result['success']) {
      _deviceToken = result['deviceToken'];
      _device = result['device'];
      _isActivated = true;

      await _storageService.saveDeviceToken(_deviceToken!);
      await _storageService.saveDeviceInfo(
        _device!.id,
        _device!.deviceCode,
        _device!.location,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deactivateDevice() async {
    await _storageService.clearDeviceData();
    _device = null;
    _deviceToken = null;
    _isActivated = false;
    notifyListeners();
  }
}
