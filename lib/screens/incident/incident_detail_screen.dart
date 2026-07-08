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
    final statusMoi = await showDialog<IncidentStatus>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Status'),
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

    if (statusMoi != null) {
      final success = await context.read<IncidentProvider>().updateStatus(
        widget.incidentId,
        statusMoi,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to "${statusMoi.displayName}"'),
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
        title: const Text('Assign Handler'),
        content: TextField(
          controller: _handlerController,
          decoration: const InputDecoration(
            labelText: 'Handler Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _handlerController.text.trim()),
            child: const Text('Assign'),
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
        ).showSnackBar(SnackBar(content: Text('Assigned to "$result"')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          Consumer<IncidentProvider>(
            builder: (context, provider, child) {
              if (provider.selected == null) return const SizedBox();
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
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
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
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final incident = provider.selected;
          if (incident == null) {
            return const Center(child: Text('Chua co thong tin'));
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
                _buildSection('Description', [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      incident.description ?? 'No description',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Address', [
                  _buildInfoRow('Address', incident.address ?? '---'),
                  _buildInfoRow('Ward', incident.neighborhood ?? '---'),
                  _buildInfoRow('Commune', incident.ward ?? '---'),
                  _buildInfoRow('District', incident.district ?? '---'),
                  _buildInfoRow('Province/City', incident.city ?? '---'),
                ]),
                const SizedBox(height: 16),
                _buildSection('Processing Info', [
                  _buildInfoRow('Status', incident.status.displayName),
                  _buildInfoRow('Handler', incident.handler ?? 'Not assigned'),
                  _buildInfoRow(
                    'Completion Date',
                    incident.completedDate != null
                        ? '${incident.completedDate!.day}/${incident.completedDate!.month}/${incident.completedDate!.year}'
                        : '---',
                  ),
                ]),
                if (incident.householdId != null) ...[
                  const SizedBox(height: 16),
                  _buildSection('Related Household', [
                    _buildInfoRow('Household ID', 'HĐ${incident.householdId}'),
                    _buildInfoRow('Owner Name', incident.headOfHousehold ?? '---'),
                    _buildInfoRow('Phone', incident.phone ?? '---'),
                  ]),
                ],
                if (incident.notes != null && incident.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection('Notes', [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(incident.notes!),
                    ),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildSection('Timeline', [
                  _buildInfoRow(
                    'Created',
                    incident.createdAt != null
                        ? '${incident.createdAt!.day}/${incident.createdAt!.month}/${incident.createdAt!.year}'
                        : '---',
                  ),
                  _buildInfoRow(
                    'Updated',
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
            label: const Text('Update Status'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _assignHandler(incident),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Assign Handler'),
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
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete incident "${provider.selected?.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
