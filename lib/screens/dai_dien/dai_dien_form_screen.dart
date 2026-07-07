import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dai_dien_model.dart';
import '../../providers/dai_dien_provider.dart';
import '../../providers/khu_pho_provider.dart';

class DaiDienFormScreen extends StatefulWidget {
  final DaiDienModel? daiDien;
  final int? khuPhoId;

  const DaiDienFormScreen({super.key, this.daiDien, this.khuPhoId});

  @override
  State<DaiDienFormScreen> createState() => _DaiDienFormScreenState();
}

class _DaiDienFormScreenState extends State<DaiDienFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hoTenController;
  late TextEditingController _soDienThoaiController;
  late TextEditingController _emailController;
  late TextEditingController _diaChiController;
  int? _selectedKhuPhoId;
  bool _isSubmitting = false;

  bool get _isEditing => widget.daiDien != null;

  @override
  void initState() {
    super.initState();
    _hoTenController = TextEditingController(text: widget.daiDien?.hoTen ?? '');
    _soDienThoaiController = TextEditingController(text: widget.daiDien?.soDienThoai ?? '');
    _emailController = TextEditingController(text: widget.daiDien?.email ?? '');
    _diaChiController = TextEditingController(text: widget.daiDien?.diaChi ?? '');
    _selectedKhuPhoId = widget.daiDien?.khuPhoId ?? widget.khuPhoId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KhuPhoProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _soDienThoaiController.dispose();
    _emailController.dispose();
    _diaChiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<DaiDienProvider>();
    final model = DaiDienModel(
      id: widget.daiDien?.id,
      hoTen: _hoTenController.text.trim(),
      soDienThoai: _soDienThoaiController.text.trim().isEmpty ? null : _soDienThoaiController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      diaChi: _diaChiController.text.trim().isEmpty ? null : _diaChiController.text.trim(),
      khuPhoId: _selectedKhuPhoId,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateDaiDien(model);
    } else {
      success = await provider.addDaiDien(model);
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
        title: Text(_isEditing ? 'Sửa đại diện' : 'Thêm đại diện'),
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
              TextFormField(
                controller: _hoTenController,
                decoration: _inputDecoration('Họ tên', 'Nhập họ tên'),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soDienThoaiController,
                decoration: _inputDecoration('Số điện thoại', 'Nhập số điện thoại'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', 'Nhập email'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diaChiController,
                decoration: _inputDecoration('Địa chỉ', 'Nhập địa chỉ'),
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Dropdown chọn khu phố
              Consumer<KhuPhoProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedKhuPhoId,
                    decoration: _inputDecoration('Khu phố phụ trách', 'Chọn khu phố'),
                    dropdownColor: const Color(0xff334155),
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white70,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('-- Chưa phân công --', style: TextStyle(color: Colors.white54)),
                      ),
                      ...provider.danhSach.map((k) => DropdownMenuItem<int>(
                        value: k.id,
                        child: Text(k.tenKhuPho, style: const TextStyle(color: Colors.white)),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedKhuPhoId = value);
                    },
                  );
                },
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