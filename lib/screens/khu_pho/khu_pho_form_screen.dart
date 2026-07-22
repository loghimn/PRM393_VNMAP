import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/khu_pho_model.dart';
import '../../providers/khu_pho_provider.dart';
import '../../providers/province_provider.dart';
import '../../services/database_service.dart';

class KhuPhoFormScreen extends StatefulWidget {
  final KhuPhoModel? khuPho;

  const KhuPhoFormScreen({super.key, this.khuPho});

  @override
  State<KhuPhoFormScreen> createState() => _KhuPhoFormScreenState();
}

class _KhuPhoFormScreenState extends State<KhuPhoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tenController;
  late TextEditingController _diaChiController;
  late TextEditingController _moTaController;
  String? _selectedProvince;
  String? _selectedCommune;
  bool _isSubmitting = false;
  List<String> _communes = [];
  bool _loadingCommunes = false;

  bool get _isEditing => widget.khuPho != null;

  @override
  void initState() {
    super.initState();
    _tenController = TextEditingController(text: widget.khuPho?.tenKhuPho ?? '');
    _diaChiController = TextEditingController(text: widget.khuPho?.diaChi ?? '');
    _moTaController = TextEditingController(text: widget.khuPho?.moTa ?? '');

    // Currently parentTen stores commune name, but we need to figure out
    // which province it belongs to by searching communes
    if (widget.khuPho?.parentTen != null) {
      _selectedCommune = widget.khuPho!.parentTen;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provProvider = context.read<ProvinceProvider>();
      if (provProvider.provinces.isEmpty) {
        provProvider.loadData();
      }
      // If editing, try to find the province for this commune
      if (_selectedCommune != null) {
        _findProvinceForCommune(_selectedCommune!);
      }
    });
  }

  Future<void> _findProvinceForCommune(String communeName) async {
    // Search through communes to find the parent province
    final service = DatabaseService();
    try {
      final provinces = context.read<ProvinceProvider>().provinces;
      for (final p in provinces) {
        final communes = await service.fetchCommunesForProvince(p.name);
        if (communes.any((c) => c.name == communeName)) {
          setState(() => _selectedProvince = p.name);
          _loadCommunes(p.name);
          break;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tenController.dispose();
    _diaChiController.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunes(String provinceName) async {
    setState(() => _loadingCommunes = true);
    try {
      final service = DatabaseService();
      final communes = await service.fetchCommunesForProvinceName(provinceName);
      setState(() {
        _communes = communes;
        // If current commune not in list, reset selection
        if (_selectedCommune != null && !communes.contains(_selectedCommune)) {
          _selectedCommune = null;
        }
      });
    } catch (e) {
      print('Error loading communes: $e');
    } finally {
      setState(() => _loadingCommunes = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<KhuPhoProvider>();
    final model = KhuPhoModel(
      id: widget.khuPho?.id,
      tenKhuPho: _tenController.text.trim(),
      diaChi: _diaChiController.text.trim().isEmpty ? null : _diaChiController.text.trim(),
      moTa: _moTaController.text.trim().isEmpty ? null : _moTaController.text.trim(),
      parentTen: _selectedCommune, // Lưu tên phường/xã
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateKhuPho(model);
    } else {
      success = await provider.addKhuPho(model);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context, model);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa khu phố' : 'Thêm khu phố'),
        backgroundColor: const Color(0xff1e293b),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tên khu phố
              TextFormField(
                controller: _tenController,
                decoration: _inputDecoration('Tên khu phố', 'Nhập tên khu phố'),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên khu phố';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown chọn tỉnh/thành
              Consumer<ProvinceProvider>(
                builder: (context, provProvider, child) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedProvince,
                    decoration: _inputDecoration('Tỉnh/Thành phố', 'Chọn tỉnh/thành'),
                    dropdownColor: const Color(0xff334155),
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white70,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('-- Chọn tỉnh/thành --', style: TextStyle(color: Colors.white54)),
                      ),
                      ...provProvider.provinces.map((p) => DropdownMenuItem<String>(
                        value: p.name,
                        child: Text(p.name, style: const TextStyle(color: Colors.white)),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                        _selectedCommune = null;
                        _communes = [];
                      });
                      if (value != null) {
                        _loadCommunes(value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Dropdown chọn phường/xã
              _buildCommuneDropdown(),

              const SizedBox(height: 16),

              TextFormField(
                controller: _diaChiController,
                decoration: _inputDecoration('Địa chỉ', 'Nhập địa chỉ'),
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moTaController,
                decoration: _inputDecoration('Mô tả', 'Nhập mô tả'),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Cập nhật' : 'Thêm mới',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommuneDropdown() {
    if (_selectedProvince == null) {
      return DropdownButtonFormField<String>(
        initialValue: null,
        decoration: _inputDecoration('Phường/Xã', 'Chọn tỉnh/thành trước'),
        dropdownColor: const Color(0xff334155),
        style: const TextStyle(color: Colors.white38),
        iconEnabledColor: Colors.white30,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('-- Chọn tỉnh/thành trước --', style: TextStyle(color: Colors.white38)),
          ),
        ],
        onChanged: null,
      );
    }

    if (_loadingCommunes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedCommune,
      decoration: _inputDecoration('Phường/Xã', 'Chọn phường/xã'),
      dropdownColor: const Color(0xff334155),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white70,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('-- Chọn phường/xã --', style: TextStyle(color: Colors.white54)),
        ),
        ..._communes.map((c) => DropdownMenuItem<String>(
          value: c,
          child: Text(c, style: const TextStyle(color: Colors.white)),
        )),
      ],
      onChanged: (value) {
        setState(() => _selectedCommune = value);
      },
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: const Color(0xff1e293b),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}