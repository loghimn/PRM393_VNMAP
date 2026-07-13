import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dia_diem_lich_su_provider.dart';
import '../../models/dia_diem_lich_su_model.dart';
import '../../utils/app_theme.dart';
import 'dia_diem_lich_su_form_screen.dart';

class DiaDiemLichSuDetailScreen extends StatefulWidget {
  final int lichSuId;

  const DiaDiemLichSuDetailScreen({super.key, required this.lichSuId});

  @override
  State<DiaDiemLichSuDetailScreen> createState() =>
      _DiaDiemLichSuDetailScreenState();
}

class _DiaDiemLichSuDetailScreenState extends State<DiaDiemLichSuDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaDiemLichSuProvider>().loadById(widget.lichSuId);
    });
  }

  Future<void> _refresh() async {
    await context.read<DiaDiemLichSuProvider>().loadById(widget.lichSuId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết địa điểm lịch sử'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final item = context.read<DiaDiemLichSuProvider>().selected;
                if (item != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaDiemLichSuFormScreen(lichSu: item),
                    ),
                  ).then((_) => _refresh());
                }
              },
            ),
        ],
      ),
      body: Consumer<DiaDiemLichSuProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selected == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.selected == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          final item = provider.selected;
          if (item == null) {
            return const Center(
              child: Text('Không tìm thấy địa điểm lịch sử.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    SizedBox(
                      height: 260,
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surfaceBackground,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, widget, progress) {
                          if (progress == null) return widget;
                          return Container(
                            color: AppColors.surfaceBackground,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 220,
                      color: AppColors.surfaceBackground,
                      child: const Center(
                        child: Icon(
                          Icons.account_balance_rounded,
                          size: 72,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ten,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (item.loaiDiTich != null)
                              _buildTag('Loại: ${item.loaiDiTich!}'),
                            if (item.thoiKy != null)
                              _buildTag('Thời kỳ: ${item.thoiKy!}'),
                            if (item.diaChi != null) _buildTag('Địa chỉ'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mô tả',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.moTa ?? 'Chưa có mô tả',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin chi tiết',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (item.diaChi != null)
                                  _buildInfoRow('Địa chỉ', item.diaChi!),
                                if (item.loaiDiTich != null)
                                  _buildInfoRow(
                                    'Loại di tích',
                                    item.loaiDiTich!,
                                  ),
                                if (item.thoiKy != null)
                                  _buildInfoRow('Thời kỳ', item.thoiKy!),
                                if (item.ghiChu != null)
                                  _buildInfoRow('Ghi chú', item.ghiChu!),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
