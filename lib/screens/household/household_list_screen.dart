import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/household_model.dart';
import 'household_detail_screen.dart';
import 'household_form_screen.dart';

class HouseholdListScreen extends StatefulWidget {
  const HouseholdListScreen({super.key});

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends State<HouseholdListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<HouseholdProvider>().loadItems(searchQuery: query);
  }

  Future<void> _deleteHousehold(Household item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa hộ gia đình "${item.headOfHousehold}"?',
        title: const Text('Xác Nhận Xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa hộ gia đình "${item.headOfHousehold}" không?',
        ),
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
      await context.read<HouseholdProvider>().delete(item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm hộ gia đình...',
                  border: InputBorder.none,
                ),
                onSubmitted: _onSearch,
              )
            : const Text('Danh sách hộ gia đình'),
            : const Text('Danh Sách Hộ Gia Đình'),
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
      body: Consumer<HouseholdProvider>(
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
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadItems(),
                    child: const Text('Thử lại'),
                    child: const Text('Thử Lại'),
                  ),
                ],
              ),
            );
          }

          if (provider.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có thông tin'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadItems(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                      child: Text(
                        item.headOfHousehold.isNotEmpty ? item.headOfHousehold[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    title: Text(
                      item.headOfHousehold,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.householdCode),
                        if (item.fullAddress.isNotEmpty)
                          Text(
                            item.fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                                    builder: (_) => HouseholdFormScreen(household: item),
                                  ),
                                );
                              } else if (value == 'delete') {
                                _deleteHousehold(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HouseholdDetailScreen(householdId: item.id!),
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
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HouseholdFormScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
                return _buildHouseholdCard(context, item, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HouseholdFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHouseholdCard(
    BuildContext context,
    Household item,
    HouseholdProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
          child: Text(
            item.headOfHousehold.isNotEmpty
                ? item.headOfHousehold[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        title: Text(
          item.headOfHousehold,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.householdCode),
            if (item.fullAddress.isNotEmpty)
              Text(
                item.fullAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HouseholdFormScreen(household: item),
                ),
              );
            } else if (value == 'delete') {
              _deleteHousehold(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HouseholdDetailScreen(householdId: item.id!),
            ),
          );
        },
      ),
    );
  }
}
