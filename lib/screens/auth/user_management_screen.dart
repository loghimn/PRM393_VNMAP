import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dbService.getAllUsers(
        searchQuery: _searchController.text,
      );
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await _dbService.updateUser(
        UserModel(
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.fullName,
          phone: user.phone,
          role: user.role,
          isActive: !user.isActive,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _changeUserRole(UserModel user, String newRole) async {
    try {
      await _dbService.updateUser(
        UserModel(
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.fullName,
          phone: user.phone,
          role: newRole,
          isActive: user.isActive,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _showRoleDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thay đổi vai trò'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('User (Người dùng)'),
              leading: Radio<String>(
                value: 'user',
                groupValue: user.role,
                onChanged: (_) {
                  Navigator.pop(ctx);
                  _changeUserRole(user, 'user');
                },
              ),
            ),
            ListTile(
              title: const Text('Admin (Quản trị viên)'),
              leading: Radio<String>(
                value: 'admin',
                groupValue: user.role,
                onChanged: (_) {
                  Navigator.pop(ctx);
                  _changeUserRole(user, 'admin');
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // Only admin can access this screen
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý người dùng')),
        body: const Center(child: Text('Bạn không có quyền truy cập trang này')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
      backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                hintText: 'Nhập tên đăng nhập hoặc email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loadUsers(),
            ),
          ),
          
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error'))
                    : _users.isEmpty
                        ? const Center(child: Text('Không có người dùng nào'))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user.role == 'admin'
                                        ? Colors.orange
                                        : Colors.blue,
                                    child: Icon(
                                      user.role == 'admin'
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(user.username),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (user.fullName != null)
                                        Text('Họ tên: ${user.fullName}'),
                                      if (user.email != null)
                                        Text('Email: ${user.email}'),
                                      Text('Vai trò: ${user.role}'),
                                      Text(
                                        'Trạng thái: ${user.isActive ? "Hoạt động" : "Đã khóa"}',
                                        style: TextStyle(
                                          color: user.isActive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'toggle_status') {
                                        _toggleUserStatus(user);
                                      } else if (value == 'change_role') {
                                        _showRoleDialog(user);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'toggle_status',
                                        child: Text(
                                          user.isActive ? 'Khóa tài khoản' : 'Mở tài khoản',
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'change_role',
                                        child: Text('Đổi vai trò'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}