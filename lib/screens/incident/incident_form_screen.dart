import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/incident_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/household_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

class IncidentFormScreen extends StatefulWidget {
  final Incident? incident;
  final int? householdId;
  final DatabaseService? databaseService;
  const IncidentFormScreen({
    super.key,
    this.incident,
    this.householdId,
    this.databaseService,
  });
  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final DatabaseService _db;
  final _storage = StorageService.instance;
  final _picker = ImagePicker();
  Timer? _phoneDebounce;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _incidentAddressController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _wardController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _handlerController;
  late final TextEditingController _notesController;
  late final TextEditingController _headOfHouseholdController;
  late final TextEditingController _phoneController;
  int? _householdId;
  bool _isSaving = false;
  bool get _isEditing => widget.incident != null;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];
  bool _isPhoneSearching = false;
  String? _phoneSearchResult;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  double _uploadProgress = 0;
  bool _isUploading = false;
  // Keys to force rebuild Autocomplete when values change programmatically
  ValueKey<String> _cityFieldKey = const ValueKey('city_init');
  ValueKey<String> _wardFieldKey = const ValueKey('ward_init');

  @override
  void initState() {
    super.initState();
    _db = widget.databaseService ?? DatabaseService();
    final inc = widget.incident;
    _householdId = widget.householdId ?? inc?.householdId;
    _titleController = TextEditingController(text: inc?.title ?? '');
    _descriptionController = TextEditingController(
      text: inc?.description ?? '',
    );
    _addressController = TextEditingController(text: inc?.address ?? '');
    _incidentAddressController = TextEditingController(
      text: inc?.incidentAddress ?? '',
    );
    _neighborhoodController = TextEditingController(
      text: inc?.neighborhood ?? '',
    );
    _wardController = TextEditingController(text: inc?.ward ?? '');
    _districtController = TextEditingController(text: inc?.district ?? '');
    _cityController = TextEditingController(text: inc?.city ?? '');
    _handlerController = TextEditingController(text: inc?.handler ?? '');
    _notesController = TextEditingController(text: inc?.notes ?? '');
    _headOfHouseholdController = TextEditingController(
      text: inc?.headOfHousehold ?? '',
    );
    _phoneController = TextEditingController(text: inc?.phone ?? '');
    if (inc != null) {
      _existingImageUrls = List.from(inc.imageUrls);
    }
    _loadDropdownData();

    // When householdId is provided (from household detail), auto-load info
    if (_householdId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final h = await _db.fetchHouseholdById(_householdId!);
        if (h != null && mounted) {
          setState(() {
            _headOfHouseholdController.text = h.headOfHousehold ?? '';
            _phoneController.text = h.phone ?? '';
            _addressController.text = h.fullAddress;
            _neighborhoodController.text = h.neighborhood ?? '';
            _wardController.text = h.ward ?? '';
            _districtController.text = h.district ?? '';
            _cityController.text = h.city ?? '';
          });
        }
      });
    }
  }

  Future<void> _loadDropdownData() async {
    final cities = await _db.fetchDistinctCities();
    List<String> wards = [];
    final sc = _cityController.text.trim();
    if (sc.isNotEmpty) {
      final m = cities.firstWhere((c) => c['name'] == sc, orElse: () => {});
      if (m.isNotEmpty)
        wards = await _db.fetchCommunesForParentCode(m['code']!);
    }
    if (mounted)
      setState(() {
        _cities = cities;
        _wards = wards;
      });
  }

  Future<void> _onCityChanged(String name) async {
    if (name.isEmpty) return;
    final m = _cities.firstWhere((c) => c['name'] == name, orElse: () => {});
    if (m.isEmpty) return;
    final wards = await _db.fetchCommunesForParentCode(m['code']!);
    if (mounted)
      setState(() {
        _wards = wards;
        _wardController.clear();
      });
  }

  @override
  void dispose() {
    _phoneDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _incidentAddressController.dispose();
    _neighborhoodController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _handlerController.dispose();
    _notesController.dispose();
    _headOfHouseholdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Look up household by phone number
  Future<void> _lookupByPhone(String phone) async {
    if (phone.length < 10) {
      setState(() {
        _phoneSearchResult = null;
        _householdId = null;
      });
      return;
    }
    setState(() {
      _isPhoneSearching = true;
      _phoneSearchResult = null;
    });
    final provider = context.read<HouseholdProvider>();
    final h = await provider.searchByPhone(phone);
    if (!mounted) return;

    if (h != null) {
      // Load cities list if needed
      if (_cities.isEmpty) {
        _cities = await _db.fetchDistinctCities();
      }

      // Tìm thành phố từ hộ gia đình và load danh sách phường/xã
      List<String> wards = _wards;
      if (h.city != null && h.city!.isNotEmpty) {
        final matchedCity = _cities.firstWhere(
          (c) => c['name'] == h.city,
          orElse: () => {},
        );
        if (matchedCity.isNotEmpty) {
          wards = await _db.fetchCommunesForParentCode(matchedCity['code']!);
        }
      }

      if (mounted) {
        setState(() {
          _householdId = h.id;
          _headOfHouseholdController.text = h.headOfHousehold ?? '';
          _phoneController.text = h.phone ?? '';
          _cityController.text = h.city ?? '';
          _wardController.text = h.ward ?? '';
          _neighborhoodController.text = h.neighborhood ?? '';
          _districtController.text = h.district ?? '';
          _addressController.text = h.fullAddress;
          _wards = wards;
          _isPhoneSearching = false;
          _phoneSearchResult =
              '✓ Đã tìm thấy: ${h.headOfHousehold} - ${h.fullAddress}';
          _cityFieldKey = ValueKey('city_${h.city}');
          _wardFieldKey = ValueKey('ward_${h.ward}');
        });
      }
    } else {
      setState(() {
        _isPhoneSearching = false;
        _householdId = null;
        _phoneSearchResult = 'Không tìm thấy hộ gia đình với SĐT này';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      final code = _isEditing
          ? widget.incident!.incidentCode
          : await _db.generateIncidentCode();
      final userId = auth.currentUser?.id;

      // ===== 1. Upload new images to Storage =====
      List<String> allImageUrls = List.from(_existingImageUrls);

      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploading = true);
        final newUrls = await _storage.uploadIncidentImages(
          incidentCode: code,
          images: _selectedImages,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
        allImageUrls.addAll(newUrls);
        setState(() => _isUploading = false);
      }

      // ===== 2. Xoá ảnh đã bị xoá khỏi _existingImageUrls =====
      if (_isEditing) {
        final removedUrls = widget.incident!.imageUrls
            .where((url) => !_existingImageUrls.contains(url))
            .toList();
        if (removedUrls.isNotEmpty) {
          await _storage.deleteFiles(removedUrls);
        }
      }

      // ===== 3. Save Incident record =====
      final inc = Incident(
        id: widget.incident?.id,
        incidentCode: code,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        incidentAddress: _incidentAddressController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        ward: _wardController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        handler: _handlerController.text.trim(),
        notes: _notesController.text.trim(),
        headOfHousehold: _headOfHouseholdController.text.trim(),
        phone: _phoneController.text.trim(),
        householdId: _householdId,
        imageUrls: allImageUrls,
        createdBy: userId,
      );
      final provider = context.read<IncidentProvider>();
      final ok = _isEditing
          ? await provider.update(inc, updatedBy: userId)
          : await provider.create(inc);
      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing ? 'Đã cập nhật sự vụ' : 'Đã tạo sự vụ mới',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Chỉnh sửa sự vụ' : 'Tạo sự vụ mới',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // ===== SECTION: TÌM KIẾM HỘ GIA ĐÌNH THEO SĐT =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.primary.withAlpha(30),
                          AppColors.primaryLight.withAlpha(15),
                        ]
                      : [
                          AppColors.primary.withAlpha(12),
                          AppColors.primaryLight.withAlpha(6),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withAlpha(isDark ? 60 : 40),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tìm kiếm hộ gia đình',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nhập SĐT để tự động lấy thông tin',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_householdId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.success.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Đã liên kết',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Số điện thoại chủ hộ',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          isRequired: true,
                          isDark: isDark,
                          onChanged: (value) {
                            // Hủy debounce trước đó và chỉ gọi API khi người dùng ngừng gõ 500ms
                            _phoneDebounce?.cancel();
                            if (value.length < 10) {
                              setState(() {
                                _phoneSearchResult = null;
                                _householdId = null;
                              });
                              return;
                            }
                            _phoneDebounce = Timer(
                              const Duration(milliseconds: 500),
                              () => _lookupByPhone(value.trim()),
                            );
                          },
                          suffixIcon: _isPhoneSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isPhoneSearching
                                ? null
                                : () => _lookupByPhone(
                                    _phoneController.text.trim(),
                                  ),
                            child: Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_phoneSearchResult != null) ...[
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _phoneSearchResult!.startsWith('✓')
                            ? AppColors.success.withAlpha(20)
                            : AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _phoneSearchResult!.startsWith('✓')
                              ? AppColors.success.withAlpha(70)
                              : AppColors.warning.withAlpha(70),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _phoneSearchResult!.startsWith('✓')
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 18,
                            color: _phoneSearchResult!.startsWith('✓')
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _phoneSearchResult!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _phoneSearchResult!.startsWith('✓')
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== SECTION: THÔNG TIN HỘ GIA ĐÌNH (tự điền) =====
            _buildSectionHeader(
              icon: Icons.family_restroom_rounded,
              title: 'Thông tin hộ gia đình',
              isDark: isDark,
              subtitle: _householdId != null ? 'Tự động từ SĐT' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _headOfHouseholdController,
              label: 'Chủ hộ',
              icon: Icons.person_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // ===== SECTION: ĐỊA CHỈ (tự điền) =====
            _buildSectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Địa chỉ',
              isDark: isDark,
              subtitle: _householdId != null ? 'Tự động từ SĐT' : null,
            ),
            const SizedBox(height: 12),
            _buildAutocompleteField(
              key: _cityFieldKey,
              label: 'Tỉnh/Thành phố',
              icon: Icons.location_city_rounded,
              ctrl: _cityController,
              items: _cities.map((c) => c['name']!).toList(),
              onChanged: _onCityChanged,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildAutocompleteField(
              key: _wardFieldKey,
              label: 'Phường/Xã',
              icon: Icons.map_rounded,
              ctrl: _wardController,
              items: _wards,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _neighborhoodController,
              label: 'Ấp/Khu phố',
              icon: Icons.holiday_village_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _districtController,
              label: 'Quận/Huyện',
              icon: Icons.account_balance_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Địa chỉ chi tiết',
              icon: Icons.home_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // ===== SECTION: ĐỊA CHỈ SỰ VIỆC =====
            _buildSectionHeader(
              icon: Icons.location_on_rounded,
              title: 'Địa chỉ sự việc',
              isDark: isDark,
              subtitle: 'Nơi xảy ra sự cố (có thể khác địa chỉ nhà)',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _incidentAddressController,
              label: 'Địa chỉ sự việc',
              icon: Icons.my_location_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // ===== SECTION: THÔNG TIN SỰ CỐ =====
            _buildSectionHeader(
              icon: Icons.info_outline_rounded,
              title: 'Thông tin sự cố',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              label: 'Tiêu đề',
              icon: Icons.title_rounded,
              isRequired: true,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả',
              icon: Icons.description_rounded,
              maxLines: 3,
              isDark: isDark,
            ),

            if (isAdmin) ...[
              const SizedBox(height: 24),

              // ===== SECTION: PHÂN CÔNG XỬ LÝ =====
              _buildSectionHeader(
                icon: Icons.assignment_ind_rounded,
                title: 'Phân công xử lý',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _handlerController,
                label: 'Người xử lý',
                icon: Icons.engineering_rounded,
                isDark: isDark,
              ),
            ],

            const SizedBox(height: 24),

            // ===== SECTION: GHI CHÚ =====
            _buildSectionHeader(
              icon: Icons.notes_rounded,
              title: 'Ghi chú',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: 'Ghi chú',
              icon: Icons.sticky_note_2_rounded,
              maxLines: 3,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // ===== SECTION: HÌNH ẢNH HIỆN TRƯỜNG =====
            _buildSectionHeader(
              icon: Icons.camera_alt_rounded,
              title: 'Hình ảnh hiện trường',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildImagePickerSection(isDark: isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Cập nhật sự vụ' : 'Tạo sự vụ mới',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(isDark ? 35 : 20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: isRequired
          ? (v) => ((v == null || v.isEmpty) ? 'Bắt buộc' : null)
          : null,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceSubtleDark
            : AppColors.surfaceSubtleLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    Key? key,
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required List<String> items,
    required bool isDark,
    void Function(String)? onChanged,
  }) {
    return _SearchDropdown(
      key: key,
      label: label,
      icon: icon,
      controller: ctrl,
      items: items,
      isDark: isDark,
      onChanged: onChanged,
    );
  }

  // ===================================================================
  // IMAGE PICKER / UPLOAD
  // ===================================================================

  Widget _buildImagePickerSection({required bool isDark}) {
    return Column(
      children: [
        // Existing images (from edit mode)
        if (_existingImageUrls.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.cloud_done_rounded,
                size: 14,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                '${_existingImageUrls.length} ảnh đã lưu',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          _existingImageUrls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceSubtleLight,
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _existingImageUrls.removeAt(i);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
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
          const SizedBox(height: 12),
        ],

        // Newly selected images (to upload)
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(
                          _selectedImages[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(i);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
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
          const SizedBox(height: 12),
        ],

        // Upload progress bar
        if (_isUploading) ...[
          LinearProgressIndicator(
            value: _uploadProgress > 0 ? _uploadProgress : null,
            backgroundColor: AppColors.primary.withAlpha(20),
            color: AppColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text(
            _uploadProgress > 0
                ? 'Đang upload ${(_uploadProgress * 100).toInt()}%'
                : 'Đang xử lý...',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],

        // Add image buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Chụp ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withAlpha(80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Thư viện'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withAlpha(80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn tối đa 10 ảnh. Dung lượng tối đa 5MB/ảnh.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImages.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Custom search dropdown widget that syncs with external controller changes.
class _SearchDropdown extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final List<String> items;
  final bool isDark;
  final void Function(String)? onChanged;

  const _SearchDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.items,
    required this.isDark,
    this.onChanged,
  });

  @override
  State<_SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<_SearchDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _SearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen) {
      _removeOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isOpen && mounted) {
          _showOverlay();
        }
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && _isOpen) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _isOpen = true;
    final filteredItems = _getFilteredItems();
    if (filteredItems.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: widget.isDark ? const Color(0xFF2A2A3E) : Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: filteredItems.length,
                shrinkWrap: true,
                itemBuilder: (ctx, i) {
                  final item = filteredItems[i];
                  return InkWell(
                    onTap: () {
                      widget.controller.text = item;
                      widget.onChanged?.call(item);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  List<String> _getFilteredItems() {
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) return widget.items;
    return widget.items.where((e) => e.toLowerCase().contains(text)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, size: 20, color: AppColors.textMuted),
          suffixIcon: Icon(
            _isOpen
                ? Icons.arrow_drop_up_rounded
                : Icons.arrow_drop_down_rounded,
            color: AppColors.textMuted,
          ),
          labelStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: widget.isDark
              ? AppColors.surfaceSubtleDark
              : AppColors.surfaceSubtleLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
