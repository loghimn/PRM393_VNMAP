import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dai_dien_provider.dart';
import '../../providers/khu_pho_provider.dart';
import '../../models/dai_dien_model.dart';
import '../../models/khu_pho_model.dart';
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
  final Set<int> _expandedKhuPhoIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DaiDienProvider>().loadData();
      context.read<KhuPhoProvider>().loadData();
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
        title: const Text('Đại diện khu phố'),
        backgroundColor: const Color(0xff1e293b),
        foregroundColor: Colors.white,
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
                hintText: 'Tìm kiếm đại diện...',
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

          // Nội dung
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildGroupedByKhuPho(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DaiDienFormScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<DaiDienProvider>(
      builder: (context, provider, child) {
        final results = provider.ketQuaTimKiem;
        if (provider.isSearching) {
          return const Center(child: CircularProgressIndicator());
        }
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return _buildDaiDienCard(item);
          },
        );
      },
    );
  }

  Widget _buildGroupedByKhuPho() {
    return Consumer2<DaiDienProvider, KhuPhoProvider>(
      builder: (context, daiDienProvider, khuPhoProvider, child) {
        if (daiDienProvider.isLoading || khuPhoProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final khuPhos = khuPhoProvider.danhSach;
        final daiDiens = daiDienProvider.danhSach;

        // Group dai diens by khu pho
        final Map<int?, List<DaiDienModel>> grouped = {};
        for (final d in daiDiens) {
          grouped.putIfAbsent(d.khuPhoId, () => []).add(d);
        }

        // Unassigned
        final unassigned = grouped[null] ?? [];

        if (khuPhos.isEmpty && daiDiens.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm khu phố và đại diện để quản lý',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              daiDienProvider.loadData(),
              khuPhoProvider.loadData(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ...khuPhos.map((khuPho) {
                final members = grouped[khuPho.id] ?? [];
                final isExpanded = _expandedKhuPhoIds.contains(khuPho.id);

                return Card(
                  color: const Color(0xff1e293b),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    key: PageStorageKey(khuPho.id),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        if (expanded) {
                          _expandedKhuPhoIds.add(khuPho.id!);
                        } else {
                          _expandedKhuPhoIds.remove(khuPho.id);
                        }
                      });
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.location_city, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      khuPho.tenKhuPho,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '${members.length} đại diện',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DaiDienFormScreen(khuPhoId: khuPho.id),
                              ),
                            );
                          },
                        ),
                        const Icon(Icons.expand_more, color: Colors.white54),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    collapsedTextColor: Colors.white,
                    textColor: Colors.white,
                    iconColor: Colors.white54,
                    collapsedIconColor: Colors.white54,
                    children: members.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Chưa có đại diện',
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                          ]
                        : members.map((d) => _buildDaiDienTile(d)).toList(),
                  ),
                );
              }),

              // Unassigned section
              if (unassigned.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4, left: 4),
                  child: Text(
                    'Chưa phân công',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
                ...unassigned.map((d) => _buildDaiDienCard(d)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaiDienTile(DaiDienModel d) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.person, color: Colors.white, size: 16),
      ),
      title: Text(
        d.hoTen,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        d.soDienThoai ?? '',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        color: const Color(0xff334155),
        onSelected: (value) async {
          if (value == 'edit') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DaiDienFormScreen(daiDien: d)),
            );
          } else if (value == 'detail') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DaiDienDetailScreen(daiDien: d)),
            );
          } else if (value == 'delete') {
            await _deleteDaiDien(d);
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
          MaterialPageRoute(builder: (_) => DaiDienDetailScreen(daiDien: d)),
        );
      },
    );
  }

  Widget _buildDaiDienCard(DaiDienModel item) {
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
                MaterialPageRoute(builder: (_) => DaiDienFormScreen(daiDien: item)),
              );
            } else if (value == 'detail') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DaiDienDetailScreen(daiDien: item)),
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
            MaterialPageRoute(builder: (_) => DaiDienDetailScreen(daiDien: item)),
          );
        },
      ),
    );
  }
}