import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;

class AuthProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
      // Lắng nghe auth state thay đổi từ Firebase Auth
      _firebaseAuth.authStateChanges().listen((firebaseUser) async {
        if (firebaseUser != null) {
          final user = await _dbService.getUserByUid(firebaseUser.uid);
          if (user != null) {
            _currentUser = user;
          } else {
            _currentUser = null;
          }
        } else {
          _currentUser = null;
        }
        _isInitialized = true;
        notifyListeners();
      });

      // Nếu đã có session, load luôn user
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final user = await _dbService.getUserByUid(firebaseUser.uid);
        if (user != null) {
          _currentUser = user;
          _isInitialized = true;
          notifyListeners();
          return;
        }
      }

      // Fallback: kiểm tra SharedPreferences (hỗ trợ người dùng cũ)
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid != null) {
        final user = await _dbService.getUserByUid(uid);
        if (user != null) {
          _currentUser = user;
        } else {
          await prefs.remove('uid');
        }
      }
    } catch (e) {
      // Silent fail - user just needs to login again
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(
        'AuthProvider.login: email="$email", password length=${password.length}',
      );

      final user = await _dbService.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.uid ?? '');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Email hoặc mật khẩu không chính xác';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi đăng nhập: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Sign out khỏi Firebase Auth
    await _firebaseAuth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    notifyListeners();
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      final success = await _dbService.changePasswordFirebase(newPassword);
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password, {
    required String email,
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

      // Validate email
      if (email.isEmpty) {
        _error = 'Vui lòng nhập email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create user model
      final user = UserModel(
        username: username,
        email: email,
        fullName: fullName,
        phone: phone,
        role: 'user',
        isActive: true,
      );

      // Firebase Auth sẽ tạo user và lưu profile vào Firestore
      await _dbService.createUserWithAuth(email, password, user);

      // Đăng nhập luôn user vừa tạo (FirebaseAuth tự động login,
      // nhưng authStateChanges listener chạy bất đồng bộ, nên cần set trực tiếp)
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final newUser = await _dbService.getUserByUid(firebaseUser.uid);
        if (newUser != null) {
          _currentUser = newUser;
        }
      }

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
