import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _showChangePassword = false;
  String? _passwordError;
  String? _passwordSuccess;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Color get _cardColor => Theme.of(context).cardColor;
  Color get _borderColor => Theme.of(context).dividerColor;
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ??
      Theme.of(context).colorScheme.onSurface;
  Color get _mutedTextColor =>
      Theme.of(context).textTheme.bodySmall?.color ??
      Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _filledInputColor =>
      Theme.of(context).inputDecorationTheme.fillColor ??
      Theme.of(context).colorScheme.surfaceVariant ??
      _cardColor;
  Color get _iconSecondaryColor =>
      Theme.of(context).iconTheme.color?.withOpacity(0.7) ?? _mutedTextColor;

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    // Simulate saving (in a real app, you'd call the API)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật thông tin thành công')),
    );
  }

  Future<void> _changePassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final oldPass = _oldPasswordController.text;

    if (newPass.length < 6) {
      setState(() {
        _passwordError = 'Mật khẩu mới phải có ít nhất 6 ký tự';
        _passwordSuccess = null;
      });
      return;
    }
    if (newPass != confirmPass) {
      setState(() {
        _passwordError = 'Mật khẩu xác nhận không khớp';
        _passwordSuccess = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(newPass);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      setState(() {
        _passwordSuccess = 'Đổi mật khẩu thành công';
        _passwordError = null;
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showChangePassword = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Đổi mật khẩu thành công',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _passwordError = 'Mật khẩu cũ không chính xác';
        _passwordSuccess = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onError,
              ),
              const SizedBox(width: 8),
              Text(
                'Đổi mật khẩu thất bại',
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.currentUser;
          if (user == null) {
            return const Center(child: Text('Vui lòng đăng nhập'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar section
                _buildAvatarSection(user),
                const SizedBox(height: 24),
                // Profile info card
                _buildInfoCard(user),
                const SizedBox(height: 16),
                // Change password section
                _buildPasswordSection(),
                const SizedBox(height: 24),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận đăng xuất'),
                          content: const Text('Bạn có chắc muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        // Xóa dữ liệu thông báo trước khi đăng xuất
                        // để tránh lộ thông báo của tài khoản này sang tài khoản khác
                        context.read<NotificationProvider>().disposeListener();
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Account info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Vai trò',
                        user.role == 'admin' ? 'Quản trị viên' : 'Người dùng',
                      ),
                      Divider(color: _borderColor),
                      _buildInfoRow(
                        'Ngày tạo',
                        user.createdAt?.toString().substring(0, 10) ?? '--',
                      ),
                      Divider(color: _borderColor),
                      _buildInfoRow(
                        'Lần cuối đăng nhập',
                        user.lastLogin?.toString().substring(0, 16) ?? '--',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user) {
    final initials = user.fullName != null && user.fullName!.isNotEmpty
        ? user.fullName![0].toUpperCase()
        : user.username[0].toUpperCase();

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.9),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName ?? user.username,
          style: TextStyle(
            color: _textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          style: TextStyle(color: _mutedTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (_isEditing) ...[
            _buildEditField(
              controller: _fullNameController,
              label: 'Họ và tên',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              controller: _phoneController,
              label: 'Số điện thoại',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ] else ...[
            _buildDetailRow(Icons.person, 'Họ và tên', user.fullName ?? '--'),
            Divider(color: _borderColor),
            _buildDetailRow(Icons.email, 'Email', user.email ?? '--'),
            Divider(color: _borderColor),
            _buildDetailRow(Icons.phone, 'Số điện thoại', user.phone ?? '--'),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _showChangePassword = !_showChangePassword),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: _mutedTextColor.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showChangePassword ? Icons.expand_less : Icons.expand_more,
                  color: _mutedTextColor.withOpacity(0.9),
                ),
              ],
            ),
          ),
          if (_showChangePassword) ...[
            const SizedBox(height: 20),
            _buildPasswordFieldFixed(
              controller: _oldPasswordController,
              label: 'Mật khẩu cũ',
              icon: Icons.lock,
              obscureText: _obscureOldPassword,
              onVisibilityChanged: (v) =>
                  setState(() => _obscureOldPassword = v),
            ),
            const SizedBox(height: 16),
            _buildPasswordFieldFixed(
              controller: _newPasswordController,
              label: 'Mật khẩu mới',
              icon: Icons.lock_open,
              obscureText: _obscureNewPassword,
              onVisibilityChanged: (v) =>
                  setState(() => _obscureNewPassword = v),
            ),
            const SizedBox(height: 16),
            _buildPasswordFieldFixed(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu mới',
              icon: Icons.lock_open,
              obscureText: _obscureConfirmPassword,
              onVisibilityChanged: (v) =>
                  setState(() => _obscureConfirmPassword = v),
            ),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _passwordError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_passwordSuccess != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _passwordSuccess!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordFieldFixed({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required ValueChanged<bool> onVisibilityChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _mutedTextColor),
        prefixIcon: Icon(icon, color: _mutedTextColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: _mutedTextColor,
          ),
          onPressed: () => onVisibilityChanged(!obscureText),
        ),
        filled: true,
        fillColor: _filledInputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _mutedTextColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: _mutedTextColor, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: _textColor, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _mutedTextColor),
        prefixIcon: Icon(icon, color: _mutedTextColor, size: 20),
        filled: true,
        fillColor: _filledInputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _mutedTextColor, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
