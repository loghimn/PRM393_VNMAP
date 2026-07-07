import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/khu_pho_provider.dart';
import '../../models/khu_pho_model.dart';
import '../../utils/app_theme.dart';
import 'khu_pho_form_screen.dart';
import 'khu_pho_detail_screen.dart';

class KhuPhoListScreen extends StatefulWidget {
  const KhuPhoListScreen({super.key});

  @override
  State<KhuPhoListScreen> createState() => _KhuPhoListScreenState();
}

class _KhuPhoListScreenState extends State<KhuPhoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KhuPhoProvider>().loadData();
    });
  }

  Future<void> _deleteKhuPho(KhuPhoModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${item.tenKhuPho}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<KhuPhoProvider>().deleteKhuPho(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách Khu phố'),
        backgroundColor: AppColors.surfaceBackground,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KhuPhoFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<KhuPhoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadData(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (provider.danhSach.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có khu phố nào',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KhuPhoFormScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm khu phố đầu tiên'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.danhSach.length,
              itemBuilder: (context, index) {
                final item = provider.danhSach[index];
                return Card(
                  color: AppColors.surfaceBackground,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.location_city, color: Colors.white),
                    ),
                    title: Text(
                      item.tenKhuPho,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.diaChi ?? 'Chưa có địa chỉ',
                          style: TextStyle(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.parentTen != null)
                          Text(
                            '📍 ${item.parentTen}',
                            style: TextStyle(color: AppColors.secondary, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      color: AppColors.surface,
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KhuPhoFormScreen(khuPho: item),
                            ),
                          );
                        } else if (value == 'detail') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KhuPhoDetailScreen(khuPho: item),
                            ),
                          );
                        } else if (value == 'delete') {
                          await _deleteKhuPho(item);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'detail', child: ListTile(leading: Icon(Icons.info, color: Colors.white), title: Text('Chi tiết', style: TextStyle(color: Colors.white)))),
                        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, color: Colors.orange), title: Text('Sửa', style: TextStyle(color: Colors.white)))),
                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Xóa', style: TextStyle(color: Colors.white)))),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KhuPhoDetailScreen(khuPho: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}