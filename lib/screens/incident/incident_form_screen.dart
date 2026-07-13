import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident_model.dart';
import '../../providers/incident_provider.dart';
import '../../providers/household_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class IncidentFormScreen extends StatefulWidget {
  final Incident? incident;
  final int? householdId;
  const IncidentFormScreen({super.key, this.incident, this.householdId});
  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
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
  bool get _isEditing => widget.incident != null;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];
  // Keys để force rebuild Autocomplete khi giá trị thay đổi programmatic
  ValueKey<String> _cityFieldKey = const ValueKey('city_init');
  ValueKey<String> _wardFieldKey = const ValueKey('ward_init');

  @override
  void initState() {
    super.initState();
    final inc = widget.incident;
    _householdId = widget.householdId ?? inc?.householdId;
    _titleController = TextEditingController(text: inc?.title ?? '');
    _descriptionController = TextEditingController(text: inc?.description ?? '');
    _addressController = TextEditingController(text: inc?.address ?? '');
    _neighborhoodController = TextEditingController(text: inc?.neighborhood ?? '');
    _descriptionController = TextEditingController(
      text: inc?.description ?? '',
    );
    _addressController = TextEditingController(text: inc?.address ?? '');
    _neighborhoodController = TextEditingController(
      text: inc?.neighborhood ?? '',
    );
    _wardController = TextEditingController(text: inc?.ward ?? '');
    _districtController = TextEditingController(text: inc?.district ?? '');
    _cityController = TextEditingController(text: inc?.city ?? '');
    _handlerController = TextEditingController(text: inc?.handler ?? '');
    _notesController = TextEditingController(text: inc?.notes ?? '');
    _headOfHouseholdController = TextEditingController(text: inc?.headOfHousehold ?? '');
    _phoneController = TextEditingController(text: inc?.phone ?? '');
    _loadDropdownData();
    if (_householdId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HouseholdProvider>().loadItems();
    _headOfHouseholdController = TextEditingController(
      text: inc?.headOfHousehold ?? '',
    );
    _phoneController = TextEditingController(text: inc?.phone ?? '');
    _loadDropdownData();
    // Khi có householdId (từ hộ gia đình), tự động load thông tin
    if (_householdId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final h = await _db.fetchHouseholdById(_householdId!);
        if (h != null && mounted) {
          _headOfHouseholdController.text = h.headOfHousehold ?? '';
          _phoneController.text = h.phone ?? '';
          _addressController.text = h.fullAddress;
          _neighborhoodController.text = h.neighborhood ?? '';
          _wardController.text = h.ward ?? '';
          _districtController.text = h.district ?? '';
          _cityController.text = h.city ?? '';
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
      if (m.isNotEmpty) wards = await _db.fetchCommunesForParentCode(m['code']!);
    }
    if (mounted) setState(() { _cities = cities; _wards = wards; });
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
    if (mounted) setState(() { _wards = wards; _wardController.clear(); });
    if (mounted)
      setState(() {
        _wards = wards;
        _wardController.clear();
      });
  }

  @override
  void dispose() {
    _titleController.dispose(); _descriptionController.dispose();
    _addressController.dispose(); _neighborhoodController.dispose();
    _wardController.dispose(); _districtController.dispose();
    _cityController.dispose(); _handlerController.dispose();
    _notesController.dispose(); _headOfHouseholdController.dispose();
    _phoneController.dispose(); super.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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

  /// Tìm kiếm hộ gia đình theo số điện thoại
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
      // Đảm bảo danh sách cities đã load
      if (_cities.isEmpty) {
        _cities = await _db.fetchDistinctCities();
      }

      // Tự động chọn tỉnh trước
      if (h.city != null && h.city!.isNotEmpty) {
        setState(() {
          _cityController.text = h.city!;
        });
        // Load danh sách phường/xã theo tỉnh đã chọn
        final matchedCity = _cities.firstWhere(
          (c) => c['name'] == h.city,
          orElse: () => {},
        );
        if (matchedCity.isNotEmpty) {
          final wards = await _db.fetchCommunesForParentCode(
            matchedCity['code']!,
          );
          if (mounted) {
            setState(() {
              _wards = wards;
              // Tự động chọn phường/xã
              _wardController.text = h.ward ?? '';
              _neighborhoodController.text = h.neighborhood ?? '';
              _districtController.text = h.district ?? '';
              _headOfHouseholdController.text = h.headOfHousehold ?? '';
              _addressController.text = h.fullAddress;
              _householdId = h.id;
              _isPhoneSearching = false;
              _phoneSearchResult =
                  '✓ Đã tìm thấy: ${h.headOfHousehold} - ${h.fullAddress}';
              // Force rebuild Autocomplete widgets
              _cityFieldKey = ValueKey('city_${h.city}');
              _wardFieldKey = ValueKey('ward_${h.ward}');
            });
          }
          return;
        }
      }

      // Nếu không có tỉnh, vẫn cập nhật các trường khác
      if (mounted) {
        setState(() {
          _householdId = h.id;
          _headOfHouseholdController.text = h.headOfHousehold ?? '';
          _neighborhoodController.text = h.neighborhood ?? '';
          _districtController.text = h.district ?? '';
          _addressController.text = h.fullAddress;
          _wardController.text = h.ward ?? '';
          _isPhoneSearching = false;
          _phoneSearchResult =
              '✓ Đã tìm thấy: ${h.headOfHousehold} - ${h.fullAddress}';
          // Force rebuild Autocomplete widgets
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
    String code = _isEditing ? widget.incident!.incidentCode : await _db.generateIncidentCode();
    final inc = Incident(id: widget.incident?.id, incidentCode: code,
      title: _titleController.text.trim(), description: _descriptionController.text.trim(),
      address: _addressController.text.trim(), neighborhood: _neighborhoodController.text.trim(),
      ward: _wardController.text.trim(), district: _districtController.text.trim(),
      city: _cityController.text.trim(), handler: _handlerController.text.trim(),
      notes: _notesController.text.trim(), headOfHousehold: _headOfHouseholdController.text.trim(),
      phone: _phoneController.text.trim(), householdId: _householdId,
    );
    final provider = context.read<IncidentProvider>();
    final ok = _isEditing ? await provider.update(inc) : await provider.create(inc);
    if (mounted) { setState(() => _isSaving = false); if (ok) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Đã cập nhật' : 'Đã tạo'))); Navigator.pop(context); } }
  }

  Widget _drop(String label, TextEditingController ctrl, List<String> items, {void Function(String)? onChanged}) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (t) => t.text.isEmpty ? items : items.where((e) => e.toLowerCase().contains(t.text.toLowerCase())),
      onSelected: (v) { ctrl.text = v; onChanged?.call(v); },
      fieldViewBuilder: (ctx, c, f, _) => TextFormField(controller: c, focusNode: f,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.arrow_drop_down))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa sự vụ' : 'Tạo sự vụ')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _s('Thông tin sự vụ'), const SizedBox(height: 8),
          TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tiêu đề *', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          _s('Địa điểm'), const SizedBox(height: 8),
          _drop('Tỉnh/Thành phố', _cityController, _cities.map((c) => c['name']!).toList(), onChanged: _onCityChanged),
          const SizedBox(height: 12),
          _drop('Phường/Xã', _wardController, _wards),
          const SizedBox(height: 12),
          TextFormField(controller: _districtController, decoration: const InputDecoration(labelText: 'Quận/Huyện', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          _s('Thông tin hộ'), const SizedBox(height: 8),
          TextFormField(controller: _headOfHouseholdController, decoration: const InputDecoration(labelText: 'Chủ hộ', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Điện thoại', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          _s('Phân công'), const SizedBox(height: 8),
          TextFormField(controller: _handlerController, decoration: const InputDecoration(labelText: 'Người xử lý', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          _s('Ghi chú'), const SizedBox(height: 8),
          TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(onPressed: _isSaving ? null : _save,
              child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Cập nhật' : 'Lưu', style: const TextStyle(fontSize: 16)))),
          const SizedBox(height: 16),
        ],
      ))),
    );
  }

  Widget _s(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));
}
    String code = _isEditing
        ? widget.incident!.incidentCode
        : await _db.generateIncidentCode();
    final inc = Incident(
      id: widget.incident?.id,
      incidentCode: code,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      ward: _wardController.text.trim(),
      district: _districtController.text.trim(),
      city: _cityController.text.trim(),
      handler: _handlerController.text.trim(),
      notes: _notesController.text.trim(),
      headOfHousehold: _headOfHouseholdController.text.trim(),
      phone: _phoneController.text.trim(),
      householdId: _householdId,
    );
    final provider = context.read<IncidentProvider>();
    final ok = _isEditing
        ? await provider.update(inc)
        : await provider.create(inc);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Đã cập nhật sự cố' : 'Đã tạo sự cố mới',
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Chỉnh sửa sự cố' : 'Tạo sự cố mới',
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
                            if (value.length >= 10) {
                              _lookupByPhone(value.trim());
                            }
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
                    _isEditing ? 'Cập nhật sự cố' : 'Tạo sự cố mới',
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
    // When items or controller text changes externally, rebuild overlay
    if (_isOpen) {
      _removeOverlay();
      // Rebuild after frame to show updated items
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
      // Delay to allow tap on item
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
    if (filteredItems.isEmpty) {
      return;
    }
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
