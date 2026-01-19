import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_api_service.dart';
import '../../models/device.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final result = await _apiService.getAllDevices(
      adminProvider.adminToken!,
      page: 1,
      limit: 50,
    );

    if (result['success']) {
      setState(() {
        _devices = result['devices'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _showCreateDeviceDialog() {
    final deviceCodeController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deviceCodeController,
              decoration: const InputDecoration(
                labelText: 'Device Code',
                hintText: 'e.g., DEV001',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Main Office',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              final result = await _apiService.createDevice(
                adminProvider.adminToken!,
                {
                  'deviceCode': deviceCodeController.text.trim(),
                  'location': locationController.text.trim(),
                  'isActive': true,
                },
              );

              if (mounted) {
                Navigator.pop(context);
                if (result['success']) {
                  final activationCode = result['activationCode'] ?? 'ERROR-NO-CODE';
                  
                  _showActivationCodeDialog(
                    deviceCodeController.text.trim(),
                    activationCode,
                  );
                  _loadDevices();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCodeForExistingDevice(Device device) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating activation code...'),
          ],
        ),
      ),
    );

    final result = await _apiService.generateActivationCode(
      adminProvider.adminToken!,
      device.id,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (result['success']) {
        final activationCode = result['activationCode'] ?? 'ERROR-NO-CODE';
        _showActivationCodeDialog(device.deviceCode, activationCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to generate code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showActivationCodeDialog(String deviceCode, String activationCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Activation Code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device "$deviceCode" has been created successfully.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Activation Code:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: SelectableText(
                activationCode,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Share this code with the device user to activate it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDeviceDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDevices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No devices found'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateDeviceDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Device'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDevices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: device.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                child: const Icon(
                                  Icons.devices,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                device.location,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Code: ${device.deviceCode}'),
                              trailing: Chip(
                                label: Text(
                                  device.isActive ? 'Active' : 'Inactive',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: device.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                              ),
                              onTap: !device.isActive
                                  ? () => _generateCodeForExistingDevice(device)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
