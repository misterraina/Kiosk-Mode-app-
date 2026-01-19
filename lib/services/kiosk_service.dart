import 'package:flutter/services.dart';

class KioskService {
  static const platform = MethodChannel('com.example.my_app/kiosk');
  
  bool _isKioskMode = false;
  
  bool get isKioskMode => _isKioskMode;

  /// Enable kiosk mode - locks the app and prevents exiting
  Future<void> enableKioskMode() async {
    try {
      _isKioskMode = true;
      
      // Lock device to this app (Android-specific)
      await platform.invokeMethod('enableKioskMode');
      
      // Disable system UI (hide navigation and status bars)
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      
      // Set preferred orientations (optional - lock to portrait)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      
      print('✅ Kiosk mode enabled');
    } catch (e) {
      print('❌ Error enabling kiosk mode: $e');
      // Fallback: just hide system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    }
  }

  /// Disable kiosk mode - allows normal app behavior
  Future<void> disableKioskMode() async {
    try {
      _isKioskMode = false;
      
      // Unlock device from this app
      await platform.invokeMethod('disableKioskMode');
      
      // Restore system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      
      // Reset orientation preferences
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      print('✅ Kiosk mode disabled');
    } catch (e) {
      print('❌ Error disabling kiosk mode: $e');
      // Fallback: restore system UI
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  /// Check if device supports kiosk mode
  Future<bool> isKioskModeSupported() async {
    try {
      final result = await platform.invokeMethod('isKioskModeSupported');
      return result as bool;
    } catch (e) {
      print('Kiosk mode check failed: $e');
      return false;
    }
  }
}
