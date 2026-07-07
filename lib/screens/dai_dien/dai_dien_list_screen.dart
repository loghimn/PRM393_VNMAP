import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dai_dien_provider.dart';
import '../../models/dai_dien_model.dart';
import 'dai_dien_form_screen.dart';
import 'dai_dien_detail_screen.dart';

class DaiDienListScreen extends StatefulWidget {
  const DaiDienListScreen({super.key});

  @override
  State<DaiDienListScreen> createState() => _DaiDienListScreenState();
}

class _DaiDienListScreenState extends State<DaiDienListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DaiDienProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteDaiDien(DaiDienModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${item.hoTen}"?'),
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
      await context.read<DaiDienProvider>().deleteDaiDien(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: const Text('Danh sách Đại diện'),
        backgroundColor: const Color(0xff1e293b),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaiDienFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xff1e293b),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đại diện (họ tên, SĐT, email)...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DaiDienProvider>().clearSearch();
                          setState(() => _isSearching = false);
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xff334155),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _isSearching = value.isNotEmpty);
                context.read<DaiDienProvider>().search(value);
              },
            ),
          ),

          // Nội dung danh sách
          Expanded(
            child: Consumer<DaiDienProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<DaiDienModel> items;
                final bool isSearching = _isSearching;
                if (isSearching) {
                  items = provider.ketQuaTimKiem;
                } else {
                  items = provider.danhSach;
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

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSearching ? 'Không tìm thấy kết quả' : 'Chưa có đại diện nào',
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        if (!isSearching) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DaiDienFormScreen()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm đại diện đầu tiên'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        color: const Color(0xff1e293b),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade700,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            item.hoTen,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.tenKhuPho != null)
                                Text(
                                  '🏘️ ${item.tenKhuPho}',
                                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                                ),
                              if (item.soDienThoai != null)
                                Text(
                                  '📞 ${item.soDienThoai}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            color: const Color(0xff334155),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DaiDienFormScreen(daiDien: item),
                                  ),
                                );
                              } else if (value == 'detail') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DaiDienDetailScreen(daiDien: item),
                                  ),
                                );
                              } else if (value == 'delete') {
                                await _deleteDaiDien(item);
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
                                builder: (_) => DaiDienDetailScreen(daiDien: item),
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
          ),
        ],
      ),
    );
  }
}