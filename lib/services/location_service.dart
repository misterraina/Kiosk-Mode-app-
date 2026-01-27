import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<Map<String, String>?> getCurrentLocation() async {
    // TODO: Fix GPS location service - using default coordinates for now
    print('Using default GPS coordinates');
    return {
      'latitude': '0.0',
      'longitude': '0.0',
    };
    
    /* Commented out until GPS issues are resolved
    try {
      // Request location permission
      final status = await Permission.location.request();
      
      if (!status.isGranted) {
        print('Location permission denied');
        return null;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service is disabled');
        return null;
      }

      // Check and request Geolocator permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Geolocator permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Geolocator permission denied forever');
        return null;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      print('Location obtained: ${position.latitude}, ${position.longitude}');

      return {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      };
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
    */
  }

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
}
