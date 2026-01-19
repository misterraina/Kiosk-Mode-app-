# PunchInPunchOut Flutter App - Architecture Documentation

## Table of Contents
1. [Current Implementation Overview](#current-implementation-overview)
2. [Project Structure](#project-structure)
3. [State Management](#state-management)
4. [JWT Token Storage & Authentication](#jwt-token-storage--authentication)
5. [Device Mode (Current)](#device-mode-current)
6. [Future: Admin Mode](#future-admin-mode)
7. [Future: Kiosk Mode](#future-kiosk-mode)
8. [Implementation Guides](#implementation-guides)

---

## Current Implementation Overview

The app is currently built as a **Device Mode** application that allows physical devices (like tablets at office entrances) to be activated and used for employee punch in/out operations.

### Technology Stack
- **Framework**: Flutter 3.10.7
- **State Management**: Provider (ChangeNotifier pattern)
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences
- **Date Formatting**: intl package

### Architecture Pattern
- **MVVM-like pattern** with Provider for state management
- **Repository pattern** for API calls (ApiService)
- **Separation of concerns**: Models, Services, Providers, Screens

---

## Project Structure

```
lib/
├── config/
│   └── api_config.dart              # API endpoints & base URL configuration
│
├── models/
│   ├── device.dart                  # Device data model
│   ├── user.dart                    # User/Employee data model
│   └── punch_record.dart            # Punch record data model
│
├── providers/
│   ├── device_provider.dart         # Device state & activation logic
│   └── punch_provider.dart          # Punch operations state
│
├── screens/
│   ├── device_activation_screen.dart    # Device activation UI
│   └── punch_screen.dart                # Punch in/out interface
│
├── services/
│   ├── api_service.dart             # HTTP API calls to backend
│   └── storage_service.dart         # Local data persistence
│
└── main.dart                        # App entry point & routing
```

---

## State Management

### Provider Architecture

The app uses **Provider** package for reactive state management with two main providers:

#### 1. DeviceProvider (`device_provider.dart`)

**Responsibilities:**
- Device activation state
- Device token management
- Device information storage
- Initialization on app startup

**State Variables:**
```dart
Device? _device;              // Current device info
String? _deviceToken;         // JWT token for device authentication
bool _isActivated;            // Activation status
bool _isLoading;              // Loading state
String? _error;               // Error messages
```

**Key Methods:**
- `initialize()` - Load saved device data on app start
- `activateDevice(deviceCode, adminToken)` - Activate device with admin credentials
- `deactivateDevice()` - Clear device data and logout

#### 2. PunchProvider (`punch_provider.dart`)

**Responsibilities:**
- Punch in/out operations
- Current punch session tracking
- User information during active session

**State Variables:**
```dart
PunchRecord? _currentPunchRecord;  // Active punch session
User? _currentUser;                // Current user who punched
bool _isLoading;                   // Loading state
String? _error;                    // Error messages
String? _successMessage;           // Success feedback
```

**Key Methods:**
- `punchIn(userId, deviceToken)` - Create punch in record
- `punchOut(userId, deviceToken)` - Close punch session
- `getUserPunchRecords(userId)` - Fetch punch history
- `clearCurrentPunch()` - Reset session state

### Provider Setup in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DeviceProvider()),
    ChangeNotifierProvider(create: (_) => PunchProvider()),
  ],
  child: MaterialApp(...)
)
```

---

## JWT Token Storage & Authentication

### Token Types

The app handles **two types of tokens**:

#### 1. Admin Token (Temporary)
- **Purpose**: Used only during device activation
- **Lifespan**: 24 hours (from backend)
- **Storage**: NOT stored locally (only used once)
- **Usage**: Passed to `/api/devices/activate` endpoint

#### 2. Device Token (Persistent)
- **Purpose**: Authenticates all punch operations
- **Lifespan**: 365 days (from backend)
- **Storage**: Stored locally using SharedPreferences
- **Usage**: Sent in `X-Device-Token` header for punch API calls

### Storage Implementation

**Location**: `services/storage_service.dart`

**Storage Keys:**
```dart
static const String _deviceTokenKey = 'device_token';
static const String _deviceCodeKey = 'device_code';
static const String _deviceLocationKey = 'device_location';
static const String _deviceIdKey = 'device_id';
```

**Storage Methods:**

```dart
// Save device token
Future<void> saveDeviceToken(String token)

// Retrieve device token
Future<String?> getDeviceToken()

// Save complete device info
Future<void> saveDeviceInfo(int id, String code, String location)

// Retrieve device info
Future<Map<String, dynamic>?> getDeviceInfo()

// Clear all device data (logout)
Future<void> clearDeviceData()

// Check if device is activated
Future<bool> isDeviceActivated()
```

### Authentication Flow

#### Device Activation Flow
```
1. User enters device code + admin token
2. App calls POST /api/devices/activate with admin token
3. Backend validates admin token
4. Backend returns device token (365-day JWT)
5. App stores device token in SharedPreferences
6. App stores device info (id, code, location)
7. Navigate to Punch Screen
```

#### Punch Operation Flow
```
1. User enters employee user ID
2. App retrieves device token from SharedPreferences
3. App calls POST /api/punch/in with X-Device-Token header
4. Backend validates device token
5. Backend creates punch record
6. App displays success message
```

#### App Initialization Flow
```
1. App starts → SplashScreen
2. DeviceProvider.initialize() called
3. Check SharedPreferences for device token
4. If token exists → Navigate to PunchScreen
5. If no token → Navigate to DeviceActivationScreen
```

### Security Considerations

**Current Implementation:**
- Device tokens stored in SharedPreferences (unencrypted)
- Suitable for dedicated device tablets
- Tokens expire after 365 days

**Production Recommendations:**
- Use `flutter_secure_storage` for encrypted token storage
- Implement token refresh mechanism
- Add device fingerprinting
- Implement certificate pinning for API calls

---

## Device Mode (Current)

### Overview
Device Mode is designed for **dedicated tablets/devices** placed at physical locations (e.g., office entrance) where employees can punch in/out.

### Features
✅ Device activation with admin credentials  
✅ Persistent device token storage  
✅ Punch in/out for employees  
✅ Display current punch status  
✅ Show employee information  
✅ Calculate work duration  
✅ Device deactivation (logout)  

### User Flow

```
┌─────────────────────────┐
│   App Launch            │
│   (SplashScreen)        │
└───────────┬─────────────┘
            │
            ▼
    ┌───────────────┐
    │ Device Token  │
    │ Exists?       │
    └───┬───────┬───┘
        │       │
     YES│       │NO
        │       │
        ▼       ▼
┌───────────┐ ┌──────────────────┐
│  Punch    │ │ Device Activation│
│  Screen   │ │ Screen           │
└───────────┘ └──────────────────┘
```

### API Endpoints Used

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/devices/activate` | POST | Admin Token | Activate device |
| `/api/punch/in` | POST | Device Token | Punch in |
| `/api/punch/out` | POST | Device Token | Punch out |
| `/api/punch/user/:userId` | GET | None | Get punch history |

---

## Future: Admin Mode

### Overview
Admin Mode will allow **administrators** to manage the system from their mobile devices or tablets.

### Proposed Features

#### Authentication
- Admin login with email/password
- Admin JWT token (24-hour expiry)
- Token refresh mechanism
- Secure token storage

#### Dashboard
- Overview statistics (total employees, currently punched in, today's attendance, active devices)
- Recent activity feed
- Quick actions

#### Device Management
- View all devices
- Create new device
- Activate/deactivate devices
- Edit device location
- View device status & last seen
- Delete devices

#### User/Employee Management
- View all employees
- Create new employee
- Edit employee details
- Change employee status (ACTIVE/DISABLED)
- View employee punch history
- Export employee data

#### Reports & Analytics
- Daily attendance report
- Employee work hours
- Device usage statistics
- Export to CSV/PDF
- Date range filtering

### Proposed Architecture

#### New Files to Create

```
lib/
├── models/
│   └── admin.dart                   # Admin user model
│
├── providers/
│   ├── admin_provider.dart          # Admin authentication state
│   ├── employee_provider.dart       # Employee management state
│   └── device_management_provider.dart  # Device management state
│
├── screens/
│   ├── admin/
│   │   ├── admin_login_screen.dart
│   │   ├── admin_dashboard_screen.dart
│   │   ├── device_management_screen.dart
│   │   ├── employee_management_screen.dart
│   │   ├── reports_screen.dart
│   │   └── settings_screen.dart
│
├── services/
│   └── admin_api_service.dart       # Admin-specific API calls
│
└── widgets/
    ├── admin/
    │   ├── device_card.dart
    │   ├── employee_card.dart
    │   └── stat_card.dart
```

---

## Future: Kiosk Mode

### Overview
Kiosk Mode is an **enhanced version of Device Mode** with additional features for a better user experience on dedicated devices.

### Proposed Features

#### Enhanced UI
- Larger touch targets for easy interaction
- Auto-logout after inactivity
- Screen saver when idle
- Voice feedback for actions
- Multi-language support

#### Employee Selection
- Search by employee code (current)
- Search by name
- QR code scanning for quick punch
- Face recognition (future integration)
- Recent employees quick access

#### Attendance Features
- Today's attendance list
- Currently in office count
- Employee photo display
- Shift information
- Break tracking

#### Kiosk Settings
- Auto-lock after X seconds
- Require admin PIN for settings
- Custom branding (logo, colors)
- Offline mode support
- Sync when online

---

## Implementation Guides

### How to Add Admin Mode

#### Step 1: Create Admin Models

```dart
// lib/models/admin.dart
class Admin {
  final int id;
  final String email;
  final String role;
  
  Admin({required this.id, required this.email, required this.role});
  
  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
```

#### Step 2: Update Storage Service

```dart
// Add to storage_service.dart
static const String _adminTokenKey = 'admin_token';
static const String _adminIdKey = 'admin_id';
static const String _adminEmailKey = 'admin_email';

Future<void> saveAdminToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_adminTokenKey, token);
}

Future<String?> getAdminToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_adminTokenKey);
}
```

#### Step 3: Create Admin Provider

```dart
// lib/providers/admin_provider.dart
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
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
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
    notifyListeners();
  }
}
```

#### Step 4: Update Main App

```dart
// lib/main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DeviceProvider()),
    ChangeNotifierProvider(create: (_) => PunchProvider()),
    ChangeNotifierProvider(create: (_) => AdminProvider()), // NEW
  ],
  child: MaterialApp(
    home: ModeSelectionScreen(), // NEW
  ),
)
```

### Migration Path

#### Phase 1: Current State (✅ Complete)
- Device Mode working
- Basic punch in/out
- Device token storage

#### Phase 2: Add Admin Mode (Recommended Next)
1. Create admin models & providers
2. Build admin login screen
3. Build device management screen
4. Build employee management screen
5. Add reports screen

#### Phase 3: Enhance to Kiosk Mode
1. Add employee search functionality
2. Implement QR code scanning
3. Add offline support
4. Implement auto-lock
5. Add attendance list view

---

## Best Practices

### State Management
- Always use `notifyListeners()` after state changes
- Use `Consumer` widgets for reactive UI updates
- Keep providers focused on single responsibility

### API Calls
- Always handle errors gracefully
- Show loading states during API calls
- Provide user feedback (success/error messages)

### Token Management
- Check token expiry before API calls
- Implement token refresh for admin mode
- Clear tokens on logout
- Use secure storage in production

---

## Conclusion

The current implementation provides a solid foundation for a punch in/out system. The architecture is designed to be extensible, allowing for easy addition of Admin Mode and Kiosk Mode in the future.

**Key Strengths:**
- Clean separation of concerns
- Reactive state management
- Persistent authentication
- Type-safe models
- Error handling

**Next Steps:**
1. Test current Device Mode thoroughly
2. Implement Admin Mode for management
3. Enhance to Kiosk Mode for better UX
4. Add offline support
5. Implement advanced features (QR, face recognition)

---

**Last Updated**: January 17, 2026  
**Version**: 1.0.0
