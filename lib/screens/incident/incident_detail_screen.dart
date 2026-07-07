import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/incident_provider.dart';
import '../../models/incident_model.dart';
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
        return Colors.blue;
      case IncidentStatus.processing:
        return Colors.orange;
      case IncidentStatus.completed:
        return Colors.green;
      case IncidentStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _updateStatus(Incident incident) async {
    final newStatus = await showDialog<IncidentStatus>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cập nhật trạng thái'),
        children: IncidentStatus.values
            .where((t) => t != incident.status)
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(t),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(t.displayName),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    if (newStatus != null) {
      final success = await context.read<IncidentProvider>().updateStatus(
        widget.incidentId,
        newStatus,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái: "${newStatus.displayName}"'),
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
        title: const Text('Giao việc'),
        content: TextField(
          controller: _handlerController,
          decoration: const InputDecoration(
            labelText: 'Tên người xử lý',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _handlerController.text.trim()),
            child: const Text('Giao'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã giao cho "$result"')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sự vụ'),
        actions: [
          Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              if (provider.selected == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncidentFormScreen(incident: provider.selected),
                      ),
                    );
                  } else if (value == 'delete') {
                    _delete(provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa', style: TextStyle(color: Colors.red)),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadById(widget.incidentId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final incident = provider.selected;
          if (incident == null) {
            return const Center(child: Text('Chưa có thông tin'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, incident),
                const SizedBox(height: 16),
                _buildActionButtons(incident),
                const SizedBox(height: 16),
                _buildSection('Mô tả', [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      incident.description ?? 'Không có mô tả',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Địa chỉ', [
                  _buildInfoRow('Địa chỉ', incident.address ?? '---'),
                  _buildInfoRow('Phường/Xã', incident.neighborhood ?? '---'),
                  _buildInfoRow('Xã/Thị trấn', incident.ward ?? '---'),
                  _buildInfoRow('Quận/Huyện', incident.district ?? '---'),
                  _buildInfoRow('Tỉnh/Thành phố', incident.city ?? '---'),
                ]),
                const SizedBox(height: 16),
                _buildSection('Thông tin xử lý', [
                  _buildInfoRow('Trạng thái', incident.status.displayName),
                  _buildInfoRow('Người xử lý', incident.handler ?? 'Chưa phân công'),
                  _buildInfoRow(
                    'Ngày hoàn thành',
                    incident.completedDate != null
                        ? '${incident.completedDate!.day}/${incident.completedDate!.month}/${incident.completedDate!.year}'
                        : '---',
                  ),
                ]),
                if (incident.householdId != null) ...[
                  const SizedBox(height: 16),
                  _buildSection('Hộ gia đình liên quan', [
                    _buildInfoRow('Mã hộ', 'HĐ${incident.householdId}'),
                    _buildInfoRow('Chủ hộ', incident.headOfHousehold ?? '---'),
                    _buildInfoRow('Điện thoại', incident.phone ?? '---'),
                  ]),
                ],
                if (incident.notes != null && incident.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection('Ghi chú', [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(incident.notes!),
                    ),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildSection('Thời gian', [
                  _buildInfoRow(
                    'Ngày tạo',
                    incident.createdAt != null
                        ? '${incident.createdAt!.day}/${incident.createdAt!.month}/${incident.createdAt!.year}'
                        : '---',
                  ),
                  _buildInfoRow(
                    'Cập nhật',
                    incident.updatedAt != null
                        ? '${incident.updatedAt!.day}/${incident.updatedAt!.month}/${incident.updatedAt!.year}'
                        : '---',
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Incident incident) {
    final status = incident.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _statusColor(status).withAlpha(30),
              child: Icon(
                Icons.report_problem,
                color: _statusColor(status),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(incident.incidentCode, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Incident incident) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: incident.status != IncidentStatus.cancelled
                ? () => _updateStatus(incident)
                : null,
            icon: const Icon(Icons.update, size: 18),
            label: const Text('Cập nhật trạng thái'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _assignHandler(incident),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Giao việc'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa sự vụ "${provider.selected?.title}"?',
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
    if (confirmed == true && provider.selected?.id != null) {
      final success = await provider.delete(provider.selected!.id!);
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}