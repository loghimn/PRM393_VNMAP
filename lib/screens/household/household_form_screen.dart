import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/household_model.dart';
import '../../providers/household_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class HouseholdFormScreen extends StatefulWidget {
  final Household? household;
  const HouseholdFormScreen({super.key, this.household});
  @override
  State<HouseholdFormScreen> createState() => _HouseholdFormScreenState();
}

class _HouseholdFormScreenState extends State<HouseholdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _scrollController = ScrollController();

  // Personal info
  late final TextEditingController _headCtrl;
  late final TextEditingController _popCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  // Address info
  late final TextEditingController _houseNumCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _neighborhoodCtrl;
  late final TextEditingController _districtCtrl;

  // Location dropdowns
  late final TextEditingController _cityCtrl;
  late final TextEditingController _wardCtrl;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];

  // Notes
  late final TextEditingController _notesCtrl;

  bool _isSaving = false;
  bool get _isEditing => widget.household != null;

  @override
  void initState() {
    super.initState();
    final h = widget.household;
    _headCtrl = TextEditingController(text: h?.headOfHousehold ?? '');
    _popCtrl = TextEditingController(text: h?.population?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: h?.phone ?? '');
    _emailCtrl = TextEditingController(text: h?.email ?? '');
    _houseNumCtrl = TextEditingController(text: h?.houseNumber ?? '');
    _streetCtrl = TextEditingController(text: h?.street ?? '');
    _neighborhoodCtrl = TextEditingController(text: h?.neighborhood ?? '');
    _districtCtrl = TextEditingController(text: h?.district ?? '');
    _cityCtrl = TextEditingController(text: h?.city ?? '');
    _wardCtrl = TextEditingController(text: h?.ward ?? '');
    _notesCtrl = TextEditingController(text: h?.notes ?? '');
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final cities = await _db.fetchDistinctCities();
    List<String> wards = [];
    final sc = _cityCtrl.text.trim();
    if (sc.isNotEmpty) {
      final m = cities.firstWhere((c) => c['name'] == sc, orElse: () => {});
      if (m.isNotEmpty) {
        wards = await _db.fetchCommunesForParentCode(m['code']!);
      }
    }
    if (mounted) {
      setState(() {
        _cities = cities;
        _wards = wards;
      });
    }
  }

  Future<void> _onCityChanged(String name) async {
    if (name.isEmpty) return;
    final m = _cities.firstWhere((c) => c['name'] == name, orElse: () => {});
    if (m.isEmpty) return;
    final wards = await _db.fetchCommunesForParentCode(m['code']!);
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
    _popCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _houseNumCtrl.dispose();
    _streetCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _wardCtrl.dispose();
    _notesCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final code = _isEditing
        ? widget.household!.householdCode
        : await _db.generateHouseholdCode();
    final h = Household(
      id: widget.household?.id,
      householdCode: code,
      headOfHousehold: _headCtrl.text.trim(),
      houseNumber: _houseNumCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      neighborhood: _neighborhoodCtrl.text.trim(),
      ward: _wardCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      population: int.tryParse(_popCtrl.text.trim()),
      notes: _notesCtrl.text.trim(),
    );
    final provider = context.read<HouseholdProvider>();
    final ok = _isEditing ? await provider.update(h) : await provider.create(h);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Đã cập nhật hộ gia đình' : 'Đã tạo hộ gia đình mới',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              title: Text(
                _isEditing ? 'Chỉnh sửa hộ gia đình' : 'Thêm hộ gia đình mới',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                    // ── Section: Personal Info ──
                    _buildSectionHeader(
                      icon: Icons.person_rounded,
                      title: 'Thông tin chủ hộ',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildField(
                            controller: _headCtrl,
                            label: 'Họ và tên chủ hộ',
                            icon: Icons.badge_rounded,
                            isRequired: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: _phoneCtrl,
                            label: 'Số điện thoại chủ hộ',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            isRequired: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
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
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
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
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildDropdown(
                            label: 'Tỉnh/Thành phố',
                            ctrl: _cityCtrl,
                            items: _cities.map((c) => c['name']!).toList(),
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
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      isDark: isDark,
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Nhập ghi chú thêm...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditing
                                        ? Icons.save_rounded
                                        : Icons.add_home_rounded,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isEditing ? 'Cập nhật' : 'Tạo hộ gia đình',
                                    style: const TextStyle(
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

  // ── Section Header ──
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 40 : 25),
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
  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight.withAlpha(128),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}
