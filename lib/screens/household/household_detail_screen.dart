import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/household_provider.dart';
import 'household_form_screen.dart';
import '../incident/incident_list_screen.dart';

class HouseholdDetailScreen extends StatefulWidget {
  final int householdId;

  const HouseholdDetailScreen({super.key, required this.householdId});

  @override
  State<HouseholdDetailScreen> createState() => _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends State<HouseholdDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().loadById(widget.householdId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Hộ Gia Đình'),
        actions: [
          Consumer<HouseholdProvider>(
            builder: (context, provider, child) {
              final household = provider.selected;
              if (household == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HouseholdFormScreen(household: household),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<HouseholdProvider>(
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
                    onPressed: () => provider.loadById(widget.householdId),
                    child: const Text('Thử Lại'),
                  ),
                ],
              ),
            );
          }

          final household = provider.selected;
          if (household == null) {
            return const Center(child: Text('Chưa có thông tin'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(30),
                          child: Text(
                            household.headOfHousehold.isNotEmpty
                                ? household.headOfHousehold[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                household.headOfHousehold,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  household.householdCode,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Address Information Card
                _buildInfoSection(context, 'Thông Tin Địa Chỉ', [
                  _buildInfoRow('Số Nhà', household.houseNumber ?? '—'),
                  _buildInfoRow('Đường', household.street ?? '—'),
                  _buildInfoRow('Ấp/Khu Phố', household.neighborhood ?? '—'),
                  _buildInfoRow('Phường/Xã', household.ward ?? '—'),
                  _buildInfoRow('Quận/Huyện', household.district ?? '—'),
                  _buildInfoRow('Tỉnh/Thành Phố', household.city ?? '—'),
                ]),
                const SizedBox(height: 12),
                // Contact Information Card
                _buildInfoSection(context, 'Thông Tin Liên Hệ', [
                  _buildInfoRow(
                    'Số ĐT',
                    (household.phone != null && household.phone!.isNotEmpty)
                        ? household.phone!
                        : '—',
                  ),
                  _buildInfoRow(
                    'Email',
                    (household.email != null && household.email!.isNotEmpty)
                        ? household.email!
                        : '—',
                  ),
                  _buildInfoRow(
                    'Số Thành Viên',
                    household.population?.toString() ?? '—',
                  ),
                ]),
                const SizedBox(height: 12),
                // Location Card
                _buildInfoSection(context, 'Vị Trí', [
                  _buildInfoRow(
                    'Kinh Độ',
                    household.longitude?.toString() ?? '—',
                  ),
                  _buildInfoRow('Vĩ Độ', household.latitude?.toString() ?? '—'),
                  if (household.longitude != null && household.latitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${household.latitude},${household.longitude}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép tọa độ'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Sao Chép Tọa Độ'),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 12),
                // Notes Card
                if (household.notes != null && household.notes!.isNotEmpty)
                  _buildInfoSection(context, 'Ghi Chú', [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(household.notes!),
                    ),
                  ]),
                const SizedBox(height: 16),
                // Related Incidents Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentListScreen(
                            householdId: widget.householdId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Xem Sự Cố Liên Quan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
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
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
