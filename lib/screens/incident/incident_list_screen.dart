import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/incident_provider.dart';
import '../../models/incident_model.dart';
import '../../utils/app_theme.dart';
import 'incident_detail_screen.dart';
import 'incident_form_screen.dart';

class IncidentListScreen extends StatefulWidget {
  final int? householdId;
  const IncidentListScreen({super.key, this.householdId});
  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  String _search = '';
  String? _statusFilter;
  String _sortBy = 'createdAt';
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().loadItems();
    });
  }

  Color _statusColor(IncidentStatus s) {
    switch (s) {
      case IncidentStatus.received:
        return AppColors.primary;
      case IncidentStatus.processing:
        return AppColors.warning;
      case IncidentStatus.completed:
        return AppColors.success;
      case IncidentStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _statusIcon(IncidentStatus s) {
    switch (s) {
      case IncidentStatus.received:
        return Icons.inbox_rounded;
      case IncidentStatus.processing:
        return Icons.autorenew_rounded;
      case IncidentStatus.completed:
        return Icons.check_circle_rounded;
      case IncidentStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildCreateButton(context, isDark),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          _buildFilterBar(isDark),
          Expanded(
            child: Consumer<IncidentProvider>(
              builder: (context, provider, child) {
                final all = provider.items;
                final filtered = all.where((inc) {
                  final matchSearch =
                      _search.isEmpty ||
                      inc.title.toLowerCase().contains(_search.toLowerCase()) ||
                      inc.incidentCode.toLowerCase().contains(
                        _search.toLowerCase(),
                      );
                  final matchStatus =
                      _statusFilter == null || inc.status.name == _statusFilter;
                  return matchSearch && matchStatus;
                }).toList();

                filtered.sort((a, b) {
                  int cmp;
                  switch (_sortBy) {
                    case 'title':
                      cmp = a.title.compareTo(b.title);
                      break;
                    case 'status':
                      cmp = a.status.index.compareTo(b.status.index);
                      break;
                    default:
                      final aDate = a.createdAt ?? DateTime(2000);
                      final bDate = b.createdAt ?? DateTime(2000);
                      cmp = aDate.compareTo(bDate);
                  }
                  return _sortAsc ? cmp : -cmp;
                });

                if (provider.isLoading && filtered.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null && filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadItems(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 64,
                          color: AppColors.textMuted.withAlpha(60),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có sự cố nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn + để thêm sự cố mới',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadItems(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildIncidentCard(
                      context,
                      filtered[i],
                      provider,
                      isDark,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sự cố...',
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () => setState(() => _search = ''),
                )
              : null,
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceSubtleDark
              : AppColors.surfaceSubtleLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tất cả',
            selected: _statusFilter == null,
            color: AppColors.primary,
            onTap: () => setState(() => _statusFilter = null),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Tiếp nhận',
            selected: _statusFilter == IncidentStatus.received.name,
            color: AppColors.primary,
            onTap: () => setState(
              () =>
                  _statusFilter = _statusFilter == IncidentStatus.received.name
                  ? null
                  : IncidentStatus.received.name,
            ),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Xử lý',
            selected: _statusFilter == IncidentStatus.processing.name,
            color: AppColors.warning,
            onTap: () => setState(
              () => _statusFilter =
                  _statusFilter == IncidentStatus.processing.name
                  ? null
                  : IncidentStatus.processing.name,
            ),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Đã xong',
            selected: _statusFilter == IncidentStatus.completed.name,
            color: AppColors.success,
            onTap: () => setState(
              () =>
                  _statusFilter = _statusFilter == IncidentStatus.completed.name
                  ? null
                  : IncidentStatus.completed.name,
            ),
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Hủy',
            selected: _statusFilter == IncidentStatus.cancelled.name,
            color: AppColors.error,
            onTap: () => setState(
              () =>
                  _statusFilter = _statusFilter == IncidentStatus.cancelled.name
                  ? null
                  : IncidentStatus.cancelled.name,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceSubtleDark
                    : AppColors.surfaceSubtleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.sort_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              setState(() {
                if (_sortBy == v) {
                  _sortAsc = !_sortAsc;
                } else {
                  _sortBy = v;
                  _sortAsc = false;
                }
              });
            },
            itemBuilder: (_) => [
              _sortItem('createdAt', 'Ngày tạo'),
              _sortItem('title', 'Tiêu đề'),
              _sortItem('status', 'Trạng thái'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label) {
    final active = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              color: active ? AppColors.primary : null,
            ),
          ),
          const Spacer(),
          if (active)
            Icon(
              _sortAsc
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<IncidentProvider>(),
                child: const IncidentFormScreen(),
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Thêm sự cố',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildIncidentCard(
    BuildContext context,
    Incident inc,
    IncidentProvider provider,
    bool isDark,
  ) {
    final sc = _statusColor(inc.status);

    return GestureDetector(
      onTap: () {
        provider.loadById(inc.id!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: IncidentDetailScreen(incidentId: inc.id!),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight.withAlpha(128),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 6),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sc.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(inc.status), color: sc, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inc.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: sc.withAlpha(isDark ? 35 : 20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inc.status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sc,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inc.incidentCode,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (inc.handler != null) ...[
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            inc.handler!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (inc.address != null && inc.address!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              inc.address!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withAlpha(120),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
