import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/household_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
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

  late final TextEditingController _headCtrl;
  late final TextEditingController _houseNumCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _neighborhoodCtrl;
  late final TextEditingController _wardCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _popCtrl;
  late final TextEditingController _notesCtrl;

  bool _isSaving = false;
  bool get _isEditing => widget.household != null;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];

  // Document upload state
  final List<File> _selectedDocuments = [];
  double _uploadProgress = 0;
  bool _isUploading = false;

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
    final selectedCity = _cityCtrl.text.trim();
    if (selectedCity.isNotEmpty) {
      final match = cities.firstWhere(
        (c) => c['name'] == selectedCity,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        wards = await _db.fetchCommunesForParentCode(match['code']!);
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
    final match = _cities.firstWhere(
      (c) => c['name'] == name,
      orElse: () => {},
    );
    if (match.isEmpty) return;
    final wards = await _db.fetchCommunesForParentCode(match['code']!);
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

    try {
      final auth = context.read<AuthProvider>();
      final code = _isEditing
          ? widget.household!.householdCode
          : await _db.generateHouseholdCode();

      // Upload documents to Storage if any
      List<String> documentUrls = widget.household?.documentUrls ?? [];
      if (_selectedDocuments.isNotEmpty) {
        _isUploading = true;
        setState(() {});
        try {
          documentUrls = await StorageService.instance.uploadHouseholdDocuments(
            householdCode: code,
            documents: _selectedDocuments,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi upload giấy tờ: $e'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() {
            _isUploading = false;
            _isSaving = false;
          });
          return;
        }
        _isUploading = false;
        setState(() {});
      }

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
        createdBy: widget.household?.createdBy ?? auth.currentUser?.id,
        documentUrls: documentUrls,
      );

      final provider = context.read<HouseholdProvider>();
      final ok = _isEditing
          ? await provider.update(h)
          : await provider.create(h);

      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Đã cập nhật hộ gia đình'
                    : 'Đã tạo hộ gia đình mới',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          final errMsg = provider.error ?? 'Lỗi không xác định';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $errMsg'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ── Pick document from gallery or camera ──
  Future<void> _pickDocument() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Thư viện ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedDocuments.add(File(picked.path)));
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
      body: CustomScrollView(
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
              title: Text(
                _isEditing ? 'Chỉnh sửa hộ gia đình' : 'Thêm hộ gia đình mới',
                style: const TextStyle(
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
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
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
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Nhập ghi chú thêm...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
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
                    // ── Section: Documents ──
                    _buildSectionHeader(
                      icon: Icons.description_rounded,
                      title: 'Giấy tờ hộ gia đình',
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pick document button
                          OutlinedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 20,
                            ),
                            label: const Text('Thêm giấy tờ / ảnh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5CF6),
                              side: const BorderSide(color: Color(0xFF8B5CF6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_selectedDocuments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            // Preview list
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedDocuments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final file = _selectedDocuments[index];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          file,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: AppColors.border
                                                    .withAlpha(40),
                                                child: const Icon(
                                                  Icons.description_rounded,
                                                  size: 32,
                                                ),
                                              ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(
                                              () => _selectedDocuments.removeAt(
                                                index,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
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
                          ],
                          // Existing documents from previous uploads
                          if (widget.household?.documentUrls != null &&
                              widget.household!.documentUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Giấy tờ đã lưu (${widget.household!.documentUrls.length})',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          // Upload progress
                          if (_isUploading) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _uploadProgress > 0
                                  ? _uploadProgress
                                  : null,
                              backgroundColor: AppColors.primary.withAlpha(20),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đang upload... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
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
                        child: _isSaving || _isUploading
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
}
