import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DeviceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Device? _device;
  int? _deviceId;
  bool _isKioskMode = false;
  bool _isActivated = false;
  bool _isLoading = false;
  String? _error;

  Device? get device => _device;
  int? get deviceId => _deviceId;
  bool get isKioskMode => _isKioskMode;
  bool get isActivated => _isActivated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;

    _deviceId = await _storageService.getDeviceId();
    _isKioskMode = await _storageService.isKioskModeEnabled();
    final deviceInfo = await _storageService.getDeviceInfo();

    if (_deviceId != null && deviceInfo != null) {
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
      _device = result['device'];
      _deviceId = _device!.id;
      _isActivated = true;

      await _storageService.saveDeviceId(_deviceId!);
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
      _device = result['device'];
      _deviceId = _device!.id;
      _isActivated = true;

      await _storageService.saveDeviceId(_deviceId!);
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

  Future<void> setKioskMode(bool enabled) async {
    _isKioskMode = enabled;
    await _storageService.setKioskMode(enabled);
    notifyListeners();
  }

  Future<void> deactivateDevice() async {
    await _storageService.clearDeviceData();
    _device = null;
    _deviceId = null;
    _isActivated = false;
    _isKioskMode = false;
    notifyListeners();
  }

  Future<void> setDeviceForAdmin(Device device) async {
    _device = device;
    _deviceId = device.id;
    _isActivated = true;
    _isKioskMode = false;
    
    await _storageService.saveDeviceId(_deviceId!);
    await _storageService.saveDeviceInfo(
      _device!.id,
      _device!.deviceCode,
      _device!.location,
    );
    
    notifyListeners();
  }
}
