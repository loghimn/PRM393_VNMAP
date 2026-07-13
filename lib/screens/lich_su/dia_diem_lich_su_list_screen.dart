import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dia_diem_lich_su_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dia_diem_lich_su_model.dart';
import '../../utils/app_theme.dart';
import 'dia_diem_lich_su_detail_screen.dart';
import 'dia_diem_lich_su_form_screen.dart';

class DiaDiemLichSuListScreen extends StatefulWidget {
  const DiaDiemLichSuListScreen({super.key});

  @override
  State<DiaDiemLichSuListScreen> createState() =>
      _DiaDiemLichSuListScreenState();
}

class _DiaDiemLichSuListScreenState extends State<DiaDiemLichSuListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaDiemLichSuProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<DiaDiemLichSuProvider>().loadItems(searchQuery: query);
  }

  Future<void> _deletePlace(DiaDiemLichSu item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa địa điểm "${item.ten}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      await context.read<DiaDiemLichSuProvider>().delete(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm địa điểm lịch sử...',
                  border: InputBorder.none,
                ),
                onSubmitted: _onSearch,
              )
            : const Text('Địa điểm lịch sử'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _onSearch('');
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DiaDiemLichSuFormScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      body: Consumer<DiaDiemLichSuProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadItems(searchQuery: _searchController.text),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Chưa có địa điểm lịch sử nào'),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiaDiemLichSuFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm địa điểm lịch sử'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.loadItems(searchQuery: _searchController.text),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item.ten,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.loaiDiTich != null)
                          Text(
                            item.loaiDiTich!,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        if (item.thoiKy != null)
                          Text(
                            'Thời kỳ: ${item.thoiKy!}',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        if (item.diaChi != null)
                          Text(
                            item.diaChi!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    trailing: isAdmin
                        ? PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DiaDiemLichSuFormScreen(lichSu: item),
                                  ),
                                );
                              } else if (value == 'delete') {
                                await _deletePlace(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Sửa'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa'),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      if (item.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DiaDiemLichSuDetailScreen(lichSuId: item.id!),
                          ),
                        );
                      }
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
