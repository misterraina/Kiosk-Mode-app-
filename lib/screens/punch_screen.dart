import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/device_provider.dart';
import '../providers/punch_provider.dart';
import '../services/kiosk_service.dart';
import 'device_activation_screen.dart';

class PunchScreen extends StatefulWidget {
  const PunchScreen({super.key});

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  final _userIdController = TextEditingController();
  final KioskService _kioskService = KioskService();
  bool _isKioskMode = false;

  @override
  void dispose() {
    if (_isKioskMode) {
      _kioskService.disableKioskMode();
    }
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _showAdminPasswordDialog(bool enableKiosk) async {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(enableKiosk ? 'Enable Kiosk Mode' : 'Disable Kiosk Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                enableKiosk
                    ? 'Enter admin password to lock device in kiosk mode'
                    : 'Enter admin password to exit kiosk mode',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simple password check (you can make this more secure)
                if (passwordController.text == 'admin123') {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      if (enableKiosk) {
        await _kioskService.enableKioskMode();
        setState(() {
          _isKioskMode = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kiosk mode enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _kioskService.disableKioskMode();
        setState(() {
          _isKioskMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kiosk mode disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePunchIn() async {
    if (_userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter User ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final punchProvider = Provider.of<PunchProvider>(context, listen: false);

    final userId = int.tryParse(_userIdController.text.trim());
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid User ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await punchProvider.punchIn(userId, deviceProvider.deviceToken!);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(punchProvider.successMessage ?? 'Punch in successful'),
            backgroundColor: Colors.green,
          ),
        );
        _userIdController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(punchProvider.error ?? 'Failed to punch in'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePunchOut() async {
    if (_userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter User ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final punchProvider = Provider.of<PunchProvider>(context, listen: false);

    final userId = int.tryParse(_userIdController.text.trim());
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid User ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await punchProvider.punchOut(userId, deviceProvider.deviceToken!);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(punchProvider.successMessage ?? 'Punch out successful'),
            backgroundColor: Colors.green,
          ),
        );
        _userIdController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(punchProvider.error ?? 'Failed to punch out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Device'),
        content: const Text('Are you sure you want to deactivate this device? You will need to activate it again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.deactivateDevice();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DeviceActivationScreen()),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'In Progress';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isKioskMode,
      onPopInvoked: (didPop) async {
        if (!didPop && _isKioskMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kiosk mode is active. Cannot exit.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Punch In/Out'),
              if (_isKioskMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'KIOSK',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !_isKioskMode,
          actions: [
            IconButton(
              icon: Icon(_isKioskMode ? Icons.lock_open : Icons.lock),
              onPressed: () => _showAdminPasswordDialog(!_isKioskMode),
              tooltip: _isKioskMode ? 'Disable Kiosk Mode' : 'Enable Kiosk Mode',
            ),
            if (!_isKioskMode)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _deactivateDevice,
                tooltip: 'Deactivate Device',
              ),
          ],
        ),
      body: Consumer2<DeviceProvider, PunchProvider>(
        builder: (context, deviceProvider, punchProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.devices, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Device Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildInfoRow('Device Code', deviceProvider.device?.deviceCode ?? 'N/A'),
                        _buildInfoRow('Location', deviceProvider.device?.location ?? 'N/A'),
                        _buildInfoRow('Status', deviceProvider.device?.isActive == true ? 'Active' : 'Inactive'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Punch Operations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'User ID',
                            hintText: 'Enter employee user ID',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: punchProvider.isLoading ? null : _handlePunchIn,
                                icon: const Icon(Icons.login),
                                label: const Text('Punch In'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: punchProvider.isLoading ? null : _handlePunchOut,
                                icon: const Icon(Icons.logout),
                                label: const Text('Punch Out'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (punchProvider.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
                if (punchProvider.currentPunchRecord != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    color: punchProvider.currentPunchRecord!.isOpen
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                punchProvider.currentPunchRecord!.isOpen
                                    ? Icons.access_time
                                    : Icons.check_circle,
                                color: punchProvider.currentPunchRecord!.isOpen
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Last Punch Record',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: punchProvider.currentPunchRecord!.isOpen
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (punchProvider.currentUser != null) ...[
                            _buildInfoRow('Employee', punchProvider.currentUser!.name),
                            _buildInfoRow('Employee Code', punchProvider.currentUser!.employeeCode),
                          ],
                          _buildInfoRow('Punch In', _formatDateTime(punchProvider.currentPunchRecord!.punchInAt)),
                          if (punchProvider.currentPunchRecord!.punchOutAt != null)
                            _buildInfoRow('Punch Out', _formatDateTime(punchProvider.currentPunchRecord!.punchOutAt!)),
                          _buildInfoRow('Duration', _formatDuration(punchProvider.currentPunchRecord!.durationMinutes)),
                          _buildInfoRow('Status', punchProvider.currentPunchRecord!.status),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
