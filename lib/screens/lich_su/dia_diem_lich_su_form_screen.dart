import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dia_diem_lich_su_model.dart';
import '../../providers/dia_diem_lich_su_provider.dart';
import '../../utils/app_theme.dart';

class DiaDiemLichSuFormScreen extends StatefulWidget {
  final DiaDiemLichSu? lichSu;

  const DiaDiemLichSuFormScreen({super.key, this.lichSu});

  @override
  State<DiaDiemLichSuFormScreen> createState() =>
      _DiaDiemLichSuFormScreenState();
}

class _DiaDiemLichSuFormScreenState extends State<DiaDiemLichSuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tenController;
  late final TextEditingController _loaiController;
  late final TextEditingController _diaChiController;
  late final TextEditingController _thoiKyController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _moTaController;
  late final TextEditingController _ghiChuController;
  bool _isSaving = false;

  bool get _isEditing => widget.lichSu != null;

  @override
  void initState() {
    super.initState();
    _tenController = TextEditingController(text: widget.lichSu?.ten ?? '');
    _loaiController = TextEditingController(
      text: widget.lichSu?.loaiDiTich ?? '',
    );
    _diaChiController = TextEditingController(
      text: widget.lichSu?.diaChi ?? '',
    );
    _thoiKyController = TextEditingController(
      text: widget.lichSu?.thoiKy ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.lichSu?.imageUrl ?? '',
    );
    _moTaController = TextEditingController(text: widget.lichSu?.moTa ?? '');
    _ghiChuController = TextEditingController(
      text: widget.lichSu?.ghiChu ?? '',
    );
  }

  @override
  void dispose() {
    _tenController.dispose();
    _loaiController.dispose();
    _diaChiController.dispose();
    _thoiKyController.dispose();
    _imageUrlController.dispose();
    _moTaController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<DiaDiemLichSuProvider>();
    final model = DiaDiemLichSu(
      id: widget.lichSu?.id,
      ten: _tenController.text.trim(),
      loaiDiTich: _loaiController.text.trim().isEmpty
          ? null
          : _loaiController.text.trim(),
      diaChi: _diaChiController.text.trim().isEmpty
          ? null
          : _diaChiController.text.trim(),
      thoiKy: _thoiKyController.text.trim().isEmpty
          ? null
          : _thoiKyController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      moTa: _moTaController.text.trim().isEmpty
          ? null
          : _moTaController.text.trim(),
      ghiChu: _ghiChuController.text.trim().isEmpty
          ? null
          : _ghiChuController.text.trim(),
    );

    final success = _isEditing
        ? await provider.update(model)
        : await provider.create(model);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Sửa địa điểm lịch sử' : 'Thêm địa điểm lịch sử',
        ),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(
                _tenController,
                'Tên di tích',
                'Nhập tên địa điểm lịch sử',
                true,
              ),
              const SizedBox(height: 16),
              _buildField(
                _loaiController,
                'Loại di tích',
                'Ví dụ: Đền, Thành cổ, Nhà thờ',
                false,
              ),
              const SizedBox(height: 16),
              _buildField(
                _diaChiController,
                'Địa chỉ',
                'Nhập địa chỉ',
                false,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildField(
                _thoiKyController,
                'Thời kỳ',
                'Ví dụ: Lê, Nguyễn, Cổ đại',
                false,
              ),
              const SizedBox(height: 16),
              _buildField(
                _imageUrlController,
                'URL ảnh',
                'Nhập đường dẫn ảnh (http... hoặc https...)',
                false,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildField(
                _moTaController,
                'Mô tả',
                'Mô tả chi tiết về địa điểm',
                false,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildField(
                _ghiChuController,
                'Ghi chú',
                'Lưu ý thêm',
                false,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Cập nhật' : 'Lưu lại',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint,
    bool isRequired, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary.withAlpha(180)),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Vui lòng nhập $label';
        }
        return null;
      },
    );
  }
}
