import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dai_dien_model.dart';
import '../../models/khu_pho_model.dart';
import '../../providers/khu_pho_provider.dart';
import '../khu_pho/khu_pho_detail_screen.dart';
import 'dai_dien_form_screen.dart';

class DaiDienDetailScreen extends StatelessWidget {
  final DaiDienModel daiDien;

  const DaiDienDetailScreen({super.key, required this.daiDien});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: Text(daiDien.hoTen),
        backgroundColor: const Color(0xff1e293b),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DaiDienFormScreen(daiDien: daiDien),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin cá nhân
            Card(
              color: const Color(0xff1e293b),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin cá nhân',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Họ tên', daiDien.hoTen),
                    _buildInfoRow('Số điện thoại', daiDien.soDienThoai ?? 'Chưa có'),
                    _buildInfoRow('Email', daiDien.email ?? 'Chưa có'),
                    _buildInfoRow('Địa chỉ', daiDien.diaChi ?? 'Chưa có'),
                    if (daiDien.createdAt != null)
                      _buildInfoRow(
                        'Ngày tạo',
                        '${daiDien.createdAt!.day}/${daiDien.createdAt!.month}/${daiDien.createdAt!.year}',
                      ),
                    if (daiDien.updatedAt != null)
                      _buildInfoRow(
                        'Cập nhật',
                        '${daiDien.updatedAt!.day}/${daiDien.updatedAt!.month}/${daiDien.updatedAt!.year}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin phân công
            Card(
              color: const Color(0xff1e293b),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phân công',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (daiDien.khuPhoId != null)
                      FutureBuilder<KhuPhoModel?>(
                        future: context.read<KhuPhoProvider>().loadData().then((_) {
                          return context.read<KhuPhoProvider>().getById(daiDien.khuPhoId!);
                        }),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final khuPho = snapshot.data;
                          if (khuPho != null) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KhuPhoDetailScreen(khuPho: khuPho),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.location_city, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Khu phố phụ trách',
                                          style: TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                        Text(
                                          khuPho.tenKhuPho,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white38),
                                ],
                              ),
                            );
                          }
                          return const Text(
                            'Đang tải thông tin khu phố...',
                            style: TextStyle(color: Colors.white54),
                          );
                        },
                      )
                    else
                      const Text(
                        'Chưa được phân công khu phố',
                        style: TextStyle(color: Colors.white54),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}