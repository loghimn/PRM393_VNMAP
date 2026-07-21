import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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

  // Avatar
  File? _avatarFile;
  bool _isUploading = false;
  double _uploadProgress = 0;

  final ImagePicker _picker = ImagePicker();

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
      Theme.of(context).colorScheme.surfaceContainerHighest ??
      _cardColor;

  /// Chọn ảnh từ Gallery hoặc Camera
  Future<void> _pickAvatar(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile != null) {
      setState(() {
        _avatarFile = File(xFile.path);
      });
    }
  }

  /// Hiển thị bottom sheet chọn nguồn ảnh
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ và tên')));
      return;
    }

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: fullName.isNotEmpty ? fullName : null,
      email: email.isNotEmpty ? email : null,
      phone: phone.isNotEmpty ? phone : null,
      avatarFile: _avatarFile,
      onUploadProgress: (progress) {
        if (mounted) {
          setState(() {
            _isUploading = true;
            _uploadProgress = progress;
          });
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isUploading = false;
      _avatarFile = null;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công')),
      );
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Lỗi cập nhật thông tin'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

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
                // Upload progress indicator
                if (_isUploading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 4),
                        Text(
                          'Đang tải ảnh lên... ${(_uploadProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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

    // Xác định ảnh hiển thị: ưu tiên ảnh vừa chọn, rồi URL từ server, rồi initials
    final bool hasNewAvatar = _avatarFile != null;
    final bool hasServerAvatar =
        user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _showImagePickerOptions : null,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _buildAvatarContent(
                    hasNewAvatar,
                    hasServerAvatar,
                    user,
                    initials,
                  ),
                ),
              ),
              // Badge edit khi đang ở chế độ edit
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
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

  Widget _buildAvatarContent(
    bool hasNewAvatar,
    bool hasServerAvatar,
    UserModel user,
    String initials,
  ) {
    if (hasNewAvatar) {
      // Ảnh vừa chọn từ gallery/camera
      return Image.file(
        _avatarFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsAvatar(initials),
      );
    }

    if (hasServerAvatar) {
      // Ảnh từ server
      return Image.network(
        user.avatarUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitialsAvatar(initials);
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsAvatar(initials),
      );
    }

    // Fallback: initials
    return _buildInitialsAvatar(initials);
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.9),
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.9),
          ],
        ),
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
                onPressed: (_isSaving || _isUploading) ? null : _saveProfile,
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
                  color: _mutedTextColor.withValues(alpha: 0.9),
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
                  color: _mutedTextColor.withValues(alpha: 0.9),
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
