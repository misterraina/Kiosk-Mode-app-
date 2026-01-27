import 'package:flutter/material.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_api_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AttendanceLogsScreen extends StatefulWidget {
  final String employeeCode;
  final String employeeName;

  const AttendanceLogsScreen({
    super.key,
    required this.employeeCode,
    required this.employeeName,
  });

  @override
  State<AttendanceLogsScreen> createState() => _AttendanceLogsScreenState();
}

class _AttendanceLogsScreenState extends State<AttendanceLogsScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final result = await _apiService.getAttendanceLogs(
      adminProvider.adminToken!,
      widget.employeeCode,
    );

    if (result['success']) {
      setState(() {
        _logs = result['logs'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs: ${widget.employeeName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchLogs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No logs found for this user'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchLogs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final timestampStr = log['timestamp_server'] ?? log['timestamp'] ?? '';
                          DateTime? timestamp;
                          try {
                            timestamp = DateTime.parse(timestampStr);
                          } catch (_) {}

                          final status = log['event'] ?? log['type'] ?? 'UNKNOWN'; 
                          final isPunchIn = status.toString().toLowerCase().contains('in');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPunchIn ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                child: Icon(
                                  isPunchIn ? Icons.login : Icons.logout,
                                  color: isPunchIn ? Colors.blue : Colors.orange,
                                ),
                              ),
                              title: Text(
                                status.toString().toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPunchIn ? Colors.blue : Colors.orange,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp != null
                                        ? DateFormat('EEEE, MMM d, yyyy').format(timestamp.toLocal())
                                        : 'Unknown Date',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    timestamp != null
                                        ? DateFormat('hh:mm:ss a').format(timestamp.toLocal())
                                        : 'Unknown Time',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: log['device_id'] != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Icon(Icons.devices, size: 16, color: Colors.grey),
                                        Text(
                                          'ID: ${log['device_id']}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
