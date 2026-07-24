import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/household_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_request_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/popup_notification.dart';
import '../household/household_request_detail_screen.dart';

class HouseholdRequestFormScreen extends StatefulWidget {
  final DatabaseService? databaseService;

  const HouseholdRequestFormScreen({super.key, this.databaseService});

  @override
  State<HouseholdRequestFormScreen> createState() =>
      _HouseholdRequestFormScreenState();
}

class _HouseholdRequestFormScreenState
    extends State<HouseholdRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _db = widget.databaseService ?? DatabaseService();
  final _scrollController = ScrollController();

  final _headCtrl = TextEditingController();
  final _houseNumCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _popCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;

  bool _isSaving = false;
  bool _isCheckingPending = true;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _checkPendingRequest();
  }

  Future<void> _checkPendingRequest() async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isCheckingPending = false);
        return;
      }

      final provider = context.read<HouseholdRequestProvider>();
      final pending = await provider.getUserPendingRequest(userId);

      if (!mounted) return;

      if (pending != null) {
        // Show pending info popup
        PopupNotification.showPendingInfo(
          context: context,
          title: 'Yêu cầu đang chờ duyệt',
          message: '',
          headName: pending.headOfHousehold,
          address: pending.fullAddress.isNotEmpty
              ? pending.fullAddress
              : 'Chưa cập nhật địa chỉ',
          statusText: 'Chờ duyệt',
          statusColor: AppColors.warning,
          onViewDetail: () {
            Navigator.pop(context);
            if (mounted && pending.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HouseholdRequestDetailScreen(requestId: pending.id!),
                ),
              );
            }
          },
          onBack: () {
            Navigator.pop(context);
            if (mounted) {
              Navigator.pop(context);
            }
          },
        );
      }
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isCheckingPending = false);
    }
  }

  Future<void> _loadDropdownData() async {
    final cities = await _db.fetchDistinctCities();
    List<String> wards = [];
    final selectedCity = _cityCtrl.text.trim();
    if (selectedCity.isNotEmpty) {
      wards = await _db.fetchCommunesForProvinceName(selectedCity);
    }
    if (mounted) {
      setState(() {
        _cities = cities;
        _wards = wards;
      });
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _onCityChanged(String name) async {
    if (name.isEmpty) return;
    debugPrint('Dropdown: Selected city "$name", fetching wards...');
    final wards = await _db.fetchCommunesForProvinceName(name);
    debugPrint(
      'Dropdown: Fetched ${wards.length} wards for "$name". Sample: ${wards.take(5).toList()}',
    );
    if (mounted) {
      setState(() {
        _wards = wards;
        _wardCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _headCtrl.dispose();
    _houseNumCtrl.dispose();
    _streetCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _wardCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _popCtrl.dispose();
    _notesCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          PopupNotification.showError(
            context: context,
            title: 'Chưa đăng nhập',
            message: 'Vui lòng đăng nhập lại để tiếp tục',
          );
        }
        return;
      }

      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        final userPhone = auth.currentUser?.phone;
        if (userPhone == null || userPhone.isEmpty) {
          setState(() => _isSaving = false);
          if (mounted) {
            PopupNotification.showError(
              context: context,
              title: 'Thiếu thông tin',
              message: 'Số điện thoại không được để trống',
            );
          }
          return;
        }
      }

      // Upload images first if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        imageUrls = await StorageService.instance.uploadMultipleFiles(
          path: 'household_requests/$timestamp',
          files: _selectedImages,
          onProgress: null,
        );
        setState(() => _isUploadingImages = false);
      }

      final request = HouseholdRequest(
        userId: userId,
        headOfHousehold: _headCtrl.text.trim(),
        houseNumber: _houseNumCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim(),
        ward: _wardCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        phone: phone.isNotEmpty ? phone : (auth.currentUser?.phone ?? ''),
        email: _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : auth.currentUser?.email,
        population: int.tryParse(_popCtrl.text.trim()),
        notes: _notesCtrl.text.trim(),
        status: 'pending',
        imageUrls: imageUrls,
      );

      final provider = context.read<HouseholdRequestProvider>();
      final ok = await provider.createRequest(request);

      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) {
          PopupNotification.showSuccess(
            context: context,
            title: 'Gửi yêu cầu thành công!',
            message:
                'Yêu cầu tạo hộ gia đình của bạn đã được gửi tới admin.\nVui lòng chờ phê duyệt.',
            buttonText: 'Đã hiểu',
            onDismiss: () {
              if (mounted) Navigator.pop(context, true);
            },
          );
        } else {
          final errMsg = provider.error ?? 'Lỗi không xác định';
          if (mounted) {
            PopupNotification.showError(
              context: context,
              title: 'Gửi yêu cầu thất bại',
              message: errMsg,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        PopupNotification.showError(
          context: context,
          title: 'Lỗi hệ thống',
          message: e.toString(),
        );
      }
    }
  }

  // ── Section Header ──
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Card wrapper ──
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Styled field ──
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.searchBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  // ── Themed Autocomplete Dropdown ──
  Widget _buildDropdown({
    required String label,
    required TextEditingController ctrl,
    required List<String> items,
    required IconData icon,
    String? hint,
    void Function(String)? onChanged,
  }) {
    return Autocomplete<String>(
      key: ValueKey('${ctrl.text}_${items.hashCode}_${items.length}'),
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (t) => t.text.isEmpty
          ? items
          : items.where((e) => e.toLowerCase().contains(t.text.toLowerCase())),
      onSelected: (v) {
        ctrl.text = v;
        onChanged?.call(v);
      },
      fieldViewBuilder: (ctx, c, f, _) => TextFormField(
        controller: c,
        focusNode: f,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withAlpha(80)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border.withAlpha(80)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.searchBg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isCheckingPending
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang kiểm tra yêu cầu...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Gradient Header ──
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 20,
                      bottom: 16,
                    ),
                    title: const Text(
                      'Yêu cầu tạo hộ gia đình',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF3B82F6),
                            Color(0xFF60A5FA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.house_rounded,
                          size: 64,
                          color: Colors.white.withAlpha(40),
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Form Content ──
                SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info notice
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.warning,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Bạn chưa có hộ gia đình. Vui lòng điền thông tin bên dưới để gửi yêu cầu tạo mới. Admin sẽ phê duyệt yêu cầu của bạn.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // ── Section: Personal Info ──
                          _buildSectionHeader(
                            icon: Icons.person_rounded,
                            title: 'Thông tin chủ hộ',
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          _buildCard(
                            child: Column(
                              children: [
                                _buildField(
                                  controller: _headCtrl,
                                  label: 'Họ và tên chủ hộ',
                                  icon: Icons.badge_rounded,
                                  isRequired: true,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Bắt buộc'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _phoneCtrl,
                                  label: 'Số điện thoại',
                                  icon: Icons.phone_rounded,
                                  keyboardType: TextInputType.phone,
                                  isRequired: true,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Bắt buộc nhập số điện thoại'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _popCtrl,
                                        label: 'Số nhân khẩu',
                                        icon: Icons.groups_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildField(
                                        controller: _emailCtrl,
                                        label: 'Email',
                                        icon: Icons.email_rounded,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ── Section: Address ──
                          _buildSectionHeader(
                            icon: Icons.location_on_rounded,
                            title: 'Địa chỉ',
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          _buildCard(
                            child: Column(
                              children: [
                                _buildDropdown(
                                  label: 'Tỉnh/Thành phố',
                                  ctrl: _cityCtrl,
                                  items: _cities
                                      .map((c) => c['name']!)
                                      .toList(),
                                  icon: Icons.location_city_rounded,
                                  hint: 'Chọn tỉnh/thành phố',
                                  onChanged: _onCityChanged,
                                ),
                                const SizedBox(height: 12),
                                _buildDropdown(
                                  label: 'Phường/Xã',
                                  ctrl: _wardCtrl,
                                  items: _wards,
                                  icon: Icons.map_rounded,
                                  hint: 'Chọn phường/xã',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _houseNumCtrl,
                                        label: 'Số nhà',
                                        icon: Icons.home_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildField(
                                        controller: _streetCtrl,
                                        label: 'Đường',
                                        icon: Icons.route_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _neighborhoodCtrl,
                                        label: 'Tổ',
                                        icon: Icons.group_work_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildField(
                                        controller: _districtCtrl,
                                        label: 'Quận/Huyện',
                                        icon: Icons.location_city_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ── Section: Notes ──
                          _buildSectionHeader(
                            icon: Icons.notes_rounded,
                            title: 'Ghi chú',
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 12),
                          _buildCard(
                            child: TextFormField(
                              controller: _notesCtrl,
                              maxLines: 3,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Nhập ghi chú thêm...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border.withAlpha(80),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border.withAlpha(80),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.searchBg,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ── Section: Hình ảnh ──
                          _buildSectionHeader(
                            icon: Icons.image_rounded,
                            title: 'Hình ảnh hộ gia đình',
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thêm ảnh chụp nhà cửa, sổ hộ khẩu (nếu có)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_selectedImages.isNotEmpty)
                                  SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                _selectedImages[index],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.black54,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                if (_selectedImages.isNotEmpty)
                                  const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(
                                      Icons.add_photo_alternate_rounded,
                                    ),
                                    label: Text(
                                      _selectedImages.isEmpty
                                          ? 'Chọn ảnh'
                                          : 'Thêm ảnh',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // ── Submit Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.send_rounded,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Gửi yêu cầu',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
