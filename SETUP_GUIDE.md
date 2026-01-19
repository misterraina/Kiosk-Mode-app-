# PunchInPunchOut Device App - Setup Guide

## 📱 Overview
This is a Flutter mobile app that connects to your PunchInPunchOut backend API. It allows devices to be activated and used for employee punch in/out operations.

## 🏗️ Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API endpoints configuration
├── models/
│   ├── device.dart              # Device data model
│   ├── user.dart                # User data model
│   └── punch_record.dart        # Punch record data model
├── providers/
│   ├── device_provider.dart     # Device state management
│   └── punch_provider.dart      # Punch operations state management
├── screens/
│   ├── device_activation_screen.dart  # Device activation UI
│   └── punch_screen.dart              # Punch in/out UI
├── services/
│   ├── api_service.dart         # HTTP API calls
│   └── storage_service.dart     # Local storage (SharedPreferences)
└── main.dart                    # App entry point
```

## 🔧 Setup Instructions

### 1. Configure Backend URL

The app is currently configured to use `http://10.0.2.2:3000` which works for Android emulator.

**For your physical device (POCO M2 Pro):**

1. Find your computer's local IP address:
   - Windows: Run `ipconfig` and look for IPv4 Address
   - Example: `192.168.1.100`

2. Update the base URL in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000';
   // Example: 'http://192.168.1.100:3000'
   ```

3. Make sure your phone and computer are on the same WiFi network

### 2. Ensure Backend is Running

Make sure your backend server is running on port 3000:
```bash
cd backend
npm start
```

### 3. Run the App

Since your app is already running, you can hot reload:
```bash
# In the terminal where flutter run is active, press 'r' for hot reload
# Or press 'R' for hot restart
```

Or restart completely:
```bash
flutter run -d 13cd1e4e
```

## 📖 How to Use the App

### Step 1: Get Admin Token

Before activating the device, you need an admin token from your backend:

**Using Postman or curl:**
```bash
POST http://localhost:3000/api/admin/login
Content-Type: application/json

{
  "email": "admin@punchinout.com",
  "password": "admin123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "admin": { ... }
}
```

Copy the `token` value.

### Step 2: Create a Device (if not already created)

**Using Postman:**
```bash
POST http://localhost:3000/api/devices
Authorization: Bearer YOUR_ADMIN_TOKEN
Content-Type: application/json

{
  "deviceCode": "DEV001",
  "location": "Main Entrance"
}
```

### Step 3: Activate Device in App

1. Open the app on your phone
2. Enter the device code (e.g., `DEV001`)
3. Paste the admin token you copied earlier
4. Click "Activate Device"

The app will:
- Call the backend to activate the device
- Receive a device token
- Store it locally for future use
- Navigate to the Punch screen

### Step 4: Create Users (if not already created)

**Using Postman:**
```bash
POST http://localhost:3000/api/users
Authorization: Bearer YOUR_ADMIN_TOKEN
Content-Type: application/json

{
  "employeeCode": "EMP001",
  "name": "John Doe",
  "status": "ACTIVE"
}
```

Note the `id` from the response (e.g., `1`).

### Step 5: Punch In/Out

1. On the Punch screen, enter the User ID (e.g., `1`)
2. Click "Punch In" to start a work session
3. Click "Punch Out" to end the session

The app will display:
- Device information
- Last punch record details
- Employee information
- Duration of work session

## 🎨 Features

### Device Activation Screen
- Enter device code and admin token
- Validates and activates the device
- Stores device token locally
- Shows helpful instructions

### Punch Screen
- Display device information
- Punch in/out operations
- Show current punch status
- Display employee details
- Calculate work duration
- Deactivate device option

### State Management
- Uses Provider for reactive state management
- Persistent storage with SharedPreferences
- Automatic token management

## 🔍 Troubleshooting

### "Network error" or "Connection refused"

1. **Check backend is running:**
   ```bash
   curl http://localhost:3000/api/health
   ```

2. **Check IP address is correct:**
   - Make sure you're using your computer's local IP, not localhost
   - Both devices must be on the same network

3. **Check firewall:**
   - Windows Firewall might be blocking port 3000
   - Add an exception for Node.js

### "Invalid device token" or "Device token required"

1. The device might not be activated properly
2. Click the logout icon to deactivate and try again
3. Make sure you're using a fresh admin token

### "User not found or not active"

1. Make sure the user exists in the database
2. Check that the user status is "ACTIVE"
3. Verify you're using the correct user ID

### "Device is not active"

1. The device was deactivated in the backend
2. Re-activate it using the admin API or the app

## 📝 API Endpoints Used

- `POST /api/devices/activate` - Activate device and get device token
- `POST /api/punch/in` - Punch in operation
- `POST /api/punch/out` - Punch out operation
- `GET /api/punch/user/:userId` - Get user punch records

## 🔐 Security Notes

- Device tokens are stored locally using SharedPreferences
- Admin tokens are only used during activation
- Device tokens are long-lived (365 days)
- Always use HTTPS in production

## 📱 Testing on Physical Device

Your POCO M2 Pro (Device ID: 13cd1e4e) is already connected. To test:

1. Update the API base URL to your computer's IP
2. Ensure backend is running and accessible
3. Hot reload the app: Press 'r' in the terminal
4. Follow the activation steps above

## 🚀 Next Steps

1. Update `api_config.dart` with your computer's IP address
2. Get an admin token from the backend
3. Activate the device in the app
4. Create test users in the backend
5. Test punch in/out operations

## 💡 Tips

- Keep the terminal with `flutter run` open to see logs
- Use hot reload (r) for quick UI changes
- Use hot restart (R) for logic changes
- Check the backend logs if API calls fail
- The app remembers the device activation between restarts
