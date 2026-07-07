import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/khu_pho_model.dart';
import '../../providers/khu_pho_provider.dart';

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
  bool _isSubmitting = false;

  bool get _isEditing => widget.khuPho != null;

  @override
  void initState() {
    super.initState();
    _tenController = TextEditingController(text: widget.khuPho?.tenKhuPho ?? '');
    _diaChiController = TextEditingController(text: widget.khuPho?.diaChi ?? '');
    _moTaController = TextEditingController(text: widget.khuPho?.moTa ?? '');
  }

  @override
  void dispose() {
    _tenController.dispose();
    _diaChiController.dispose();
    _moTaController.dispose();
    super.dispose();
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