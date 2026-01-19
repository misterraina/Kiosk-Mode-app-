import 'package:flutter/foundation.dart';
import '../models/punch_record.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class PunchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  PunchRecord? _currentPunchRecord;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  PunchRecord? get currentPunchRecord => _currentPunchRecord;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasPunchedIn => _currentPunchRecord != null && _currentPunchRecord!.isOpen;

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> punchIn(int userId, String deviceToken) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final result = await _apiService.punchIn(userId, deviceToken);

    if (result['success']) {
      _currentPunchRecord = result['punchRecord'];
      _currentUser = result['user'];
      _successMessage = result['message'];
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

  Future<bool> punchOut(int userId, String deviceToken) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final result = await _apiService.punchOut(userId, deviceToken);

    if (result['success']) {
      _currentPunchRecord = result['punchRecord'];
      _successMessage = result['message'];
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

  Future<List<PunchRecord>> getUserPunchRecords(int userId, {String? status}) async {
    final result = await _apiService.getUserPunchRecords(userId, status: status);

    if (result['success']) {
      return result['punchRecords'];
    } else {
      return [];
    }
  }

  void clearCurrentPunch() {
    _currentPunchRecord = null;
    _currentUser = null;
    notifyListeners();
  }
}
