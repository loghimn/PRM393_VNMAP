import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../models/incident_model.dart';
import '../../utils/app_theme.dart';
import 'incident_form_screen.dart';

class IncidentDetailScreen extends StatefulWidget {
  final int incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _handlerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().loadById(widget.incidentId);
    });
  }

  @override
  void dispose() {
    _handlerController.dispose();
    super.dispose();
  }

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.received:
        return const Color(0xFF2196F3);
      case IncidentStatus.processing:
        return const Color(0xFFFF9800);
      case IncidentStatus.completed:
        return const Color(0xFF4CAF50);
      case IncidentStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }

  IconData _statusIcon(IncidentStatus status) {
    switch (status) {
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

  Future<void> _updateStatus(Incident incident) async {
    final newStatus = await showDialog<IncidentStatus>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: IncidentStatus.values
              .where((t) => t != incident.status)
              .map(
                (t) => ListTile(
                  onTap: () => Navigator.pop(ctx, t),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor(t).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(t),
                      color: _statusColor(t),
                      size: 22,
                    ),
                  ),
                  title: Text(t.displayName),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (newStatus != null) {
      final auth = context.read<AuthProvider>();
      final success = await context.read<IncidentProvider>().updateStatus(
        widget.incidentId,
        newStatus,
        updatedBy: auth.currentUser?.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái: ${newStatus.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _assignHandler(Incident incident) async {
    _handlerController.text = incident.handler ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Phân công xử lý'),
        content: TextField(
          controller: _handlerController,
          decoration: InputDecoration(
            labelText: 'Tên người xử lý',
            prefixIcon: const Icon(Icons.person_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _handlerController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Phân công'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await context.read<IncidentProvider>().assignHandler(
        widget.incidentId,
        result,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã phân công cho "$result"'),
            backgroundColor: AppColors.success,
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
        title: const Text('Chi tiết sự cố'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              if (provider.selected == null) return const SizedBox();
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            IncidentFormScreen(incident: provider.selected),
                      ),
                    );
                  } else if (value == 'delete') {
                    _delete(provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Text('Xóa', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<IncidentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => provider.loadById(widget.incidentId),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          final incident = provider.selected;
          if (incident == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không tìm thấy thông tin',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final statusColor = _statusColor(incident.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              children: [
                // ── Status Banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withAlpha(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _statusIcon(incident.status),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        incident.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          incident.status.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        incident.incidentCode,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Action Buttons ──
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    if (auth.isAdmin) {
                      return Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.update_rounded,
                              label: 'Cập nhật trạng thái',
                              color: const Color(0xFF2196F3),
                              onTap: incident.status != IncidentStatus.cancelled
                                  ? () => _updateStatus(incident)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.person_add_rounded,
                              label: 'Phân công',
                              color: AppColors.primary,
                              onTap: () => _assignHandler(incident),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (Provider.of<AuthProvider>(context, listen: false).isAdmin)
                  const SizedBox(height: 16),

                // ── Description ──
                _buildSection(
                  icon: Icons.description_rounded,
                  title: 'Mô tả',
                  children: [
                    Text(
                      incident.description ?? 'Không có mô tả',
                      style: TextStyle(
                        fontSize: 15,
                        color: incident.description != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Address ──
                _buildSection(
                  icon: Icons.location_on_outlined,
                  title: 'Địa chỉ',
                  children: [
                    _buildInfoRow(
                      Icons.home_rounded,
                      'Địa chỉ',
                      incident.address,
                    ),
                    _buildInfoRow(
                      Icons.holiday_village_rounded,
                      'Ấp/Khu phố',
                      incident.neighborhood,
                    ),
                    _buildInfoRow(
                      Icons.map_rounded,
                      'Phường/Xã',
                      incident.ward,
                    ),
                    _buildInfoRow(
                      Icons.account_balance_rounded,
                      'Quận/Huyện',
                      incident.district,
                    ),
                    _buildInfoRow(
                      Icons.location_city_rounded,
                      'Tỉnh/Thành phố',
                      incident.city,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Processing Info ──
                _buildSection(
                  icon: Icons.engineering_rounded,
                  title: 'Xử lý',
                  children: [
                    _buildStatusRow(incident.status),
                    _buildInfoRow(
                      Icons.person_rounded,
                      'Người xử lý',
                      incident.handler,
                    ),
                    _buildInfoRow(
                      Icons.event_rounded,
                      'Ngày hoàn thành',
                      incident.completedDate,
                    ),
                  ],
                ),

                // ── Related Household ──
                if (incident.householdId != null) ...[
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.family_restroom_rounded,
                    title: 'Hộ gia đình liên quan',
                    children: [
                      _buildInfoRow(
                        Icons.qr_code_rounded,
                        'Mã HĐ',
                        'HĐ${incident.householdId}',
                      ),
                      _buildInfoRow(
                        Icons.person_rounded,
                        'Chủ hộ',
                        incident.headOfHousehold,
                      ),
                      _buildInfoRow(
                        Icons.phone_rounded,
                        'Số ĐT',
                        incident.phone,
                      ),
                    ],
                  ),
                ],

                // ── Notes ──
                if (incident.notes != null && incident.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection(
                    icon: Icons.notes_rounded,
                    title: 'Ghi chú',
                    children: [
                      Text(
                        incident.notes!,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Timeline ──
                const SizedBox(height: 12),
                _buildSection(
                  icon: Icons.timeline_rounded,
                  title: 'Thời gian',
                  children: [
                    _buildInfoRow(
                      Icons.add_circle_outline_rounded,
                      'Tạo lúc',
                      incident.createdAt,
                    ),
                    _buildInfoRow(
                      Icons.update_rounded,
                      'Cập nhật lúc',
                      incident.updatedAt,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    String displayValue;
    if (value == null) {
      displayValue = '---';
    } else if (value is DateTime) {
      displayValue =
          '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    } else {
      displayValue = value.toString();
    }

    final isEmpty = displayValue == '---';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isEmpty ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IncidentStatus status) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              'Trạng thái',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(IncidentProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa sự cố "${provider.selected?.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && provider.selected?.id != null) {
      final auth = context.read<AuthProvider>();
      final success = await provider.delete(
        provider.selected!.id!,
        deletedBy: auth.currentUser?.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa sự cố'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color.withAlpha(15) : Colors.grey.withAlpha(10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? color.withAlpha(60) : Colors.grey.withAlpha(30),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: enabled ? color : Colors.grey),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
