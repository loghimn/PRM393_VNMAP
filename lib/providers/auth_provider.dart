import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId != null) {
        final user = await _dbService.getUserById(userId);
        if (user != null) {
          _currentUser = user;
        } else {
          await prefs.remove('userId');
        }
      }
    } catch (e) {
      // Silent fail - user just needs to login again
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(
        'AuthProvider.login: phone="$phone", password length=${password.length}',
      );

      final user = await _dbService.login(phone, password);
      if (user != null) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Số điện thoại hoặc mật khẩu không chính xác';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser?.id == null) return false;
    try {
      final success = await _dbService.changePassword(
        _currentUser!.id!,
        oldPassword,
        newPassword,
      );
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password, {
    String? email,
    String? fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate username
      if (username.isEmpty || username.length < 3) {
        _error = 'Tên đăng nhập phải có ít nhất 3 ký tự';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate password
      if (password.isEmpty || password.length < 6) {
        _error = 'Mật khẩu phải có ít nhất 6 ký tự';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if phone already exists
      if (phone == null || phone.trim().isEmpty) {
        _error = 'Vui lòng nhập số điện thoại';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final existingUser = await _dbService.getUserByPhone(phone);
      if (existingUser != null) {
        _error = 'Số điện thoại đã được đăng ký';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create user with default role 'user'
      final user = UserModel(
        username: username,
        passwordHash: null, // Will be set by database service
        email: email,
        fullName: fullName,
        phone: phone,
        role: 'user',
        isActive: true,
      );

      await _dbService.createUser(user, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi đăng ký: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
