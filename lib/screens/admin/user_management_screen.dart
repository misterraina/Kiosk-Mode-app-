import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_api_service.dart';
import '../../models/user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final result = await _apiService.getAllUsers(
      adminProvider.adminToken!,
      page: 1,
      limit: 50,
    );

    if (result['success']) {
      setState(() {
        _users = result['users'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _showCreateUserDialog() {
    final employeeCodeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: employeeCodeController,
              decoration: const InputDecoration(
                labelText: 'Employee Code',
                hintText: 'e.g., EMP001',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., John Doe',
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
              final result = await _apiService.createUser(
                adminProvider.adminToken!,
                {
                  'employeeCode': employeeCodeController.text.trim(),
                  'name': nameController.text.trim(),
                  'status': 'ACTIVE',
                },
              );

              if (mounted) {
                Navigator.pop(context);
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.green,
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
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No users found'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateUserDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create User'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.status == 'ACTIVE'
                                    ? Colors.green
                                    : Colors.grey,
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Code: ${user.employeeCode}'),
                              trailing: Chip(
                                label: Text(
                                  user.status,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: user.status == 'ACTIVE'
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
