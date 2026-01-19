import 'package:flutter/foundation.dart';
import '../models/admin.dart';
import '../services/admin_api_service.dart';
import '../services/storage_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  final StorageService _storageService = StorageService();

  Admin? _admin;
  String? _adminToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  Admin? get admin => _admin;
  String? get adminToken => _adminToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    
    final token = await _storageService.getAdminToken();
    final adminInfo = await _storageService.getAdminInfo();

    if (token != null && adminInfo != null) {
      _adminToken = token;
      _admin = Admin(
        id: adminInfo['id'],
        email: adminInfo['email'],
        role: adminInfo['role'],
      );
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.login(email, password);

    if (result['success']) {
      _adminToken = result['token'];
      _admin = result['admin'];
      _isAuthenticated = true;

      await _storageService.saveAdminToken(_adminToken!);
      await _storageService.saveAdminInfo(
        _admin!.id,
        _admin!.email,
        _admin!.role,
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

  Future<void> logout() async {
    await _storageService.clearAdminData();
    _admin = null;
    _adminToken = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
