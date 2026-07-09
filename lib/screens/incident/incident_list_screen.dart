import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/incident_model.dart';
import 'incident_detail_screen.dart';
import 'incident_form_screen.dart';

class IncidentListScreen extends StatefulWidget {
  final int? householdId;

  const IncidentListScreen({super.key, this.householdId});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().loadItems(
        householdId: widget.householdId,
      );
      context.read<IncidentProvider>().loadNeighborhoodList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<IncidentProvider>().loadItems(
      searchQuery: query,
      householdId: widget.householdId,
    );
  }

  Future<void> _deleteIncident(Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa sự vụ "${incident.title}"?',
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
    if (confirmed == true && incident.id != null) {
      await context.read<IncidentProvider>().delete(incident.id!);
    }
  }

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.received:
        return Colors.blue;
      case IncidentStatus.processing:
        return Colors.orange;
      case IncidentStatus.completed:
        return Colors.green;
      case IncidentStatus.cancelled:
        return Colors.red;
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
                  hintText: 'Tìm kiếm sự vụ...',
                  border: InputBorder.none,
                ),
                onSubmitted: _onSearch,
              )
            : const Text('Danh sách sự vụ'),
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
      body: Consumer<IncidentProvider>(
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
                    onPressed: () =>
                        provider.loadItems(householdId: widget.householdId),
                    child: const Text('Thử lại'),
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
                  Icon(
                    Icons.report_problem_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Chưa có thông tin'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.loadItems(householdId: widget.householdId),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final incident = provider.items[index];
                final status = incident.status;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(status).withAlpha(30),
                      child: Icon(
                        Icons.report_problem,
                        color: _statusColor(status),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      incident.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(incident.incidentCode),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                    builder: (_) => IncidentFormScreen(incident: incident),
                                  ),
                                );
                              } else if (value == 'delete') {
                                _deleteIncident(incident);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentDetailScreen(incidentId: incident.id!),
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
                  MaterialPageRoute(
                    builder: (_) => IncidentFormScreen(householdId: widget.householdId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}