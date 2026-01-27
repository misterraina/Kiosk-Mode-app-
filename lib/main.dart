import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'providers/punch_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/face_punch_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => PunchProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'PunchInPunchOut',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    await Future.wait([
      deviceProvider.initialize(),
      adminProvider.initialize(),
    ]);

    if (mounted) {
      Widget destination;
      
      // If admin is authenticated, go to admin dashboard
      if (adminProvider.isAuthenticated) {
        destination = const AdminDashboardScreen();
      } else {
        // Default to Face Punch Screen as main entry point
        destination = const FacePunchScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face,
              size: 80,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 24),
            const Text(
              'PunchInPunchOut',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
