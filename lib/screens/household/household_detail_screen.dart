import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/household_provider.dart';
import '../../utils/app_theme.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chi tiết hộ gia đình',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
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
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.surfaceBackground,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text('Sửa'),
                      ],
                    ),
                  ),
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Có lỗi xảy ra',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadById(widget.householdId),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final household = provider.selected;
          if (household == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: AppColors.textMuted.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chưa có thông tin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppColors.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white.withAlpha(30),
                          child: Text(
                            household.headOfHousehold.isNotEmpty
                                ? household.headOfHousehold[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  household.householdCode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 20),
                // Address Information Card
                _buildInfoSection(
                  context,
                  'Thông tin địa chỉ',
                  Icons.location_on_rounded,
                  AppColors.primary,
                  isDark,
                  [
                    _buildInfoRow(
                      Icons.home_rounded,
                      'Số nhà',
                      household.houseNumber ?? '—',
                    ),
                    _buildInfoRow(
                      Icons.route_rounded,
                      'Đường',
                      household.street ?? '—',
                    ),
                    _buildInfoRow(
                      Icons.group_work_rounded,
                      'Khu phố',
                      household.neighborhood ?? '—',
                    ),
                    _buildInfoRow(
                      Icons.map_rounded,
                      'Phường/Xã',
                      household.ward ?? '—',
                    ),
                    _buildInfoRow(
                      Icons.location_city_rounded,
                      'Quận/Huyện',
                      household.district ?? '—',
                    ),
                    _buildInfoRow(
                      Icons.location_city_rounded,
                      'Tỉnh/Thành phố',
                      household.city ?? '—',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Contact Information Card
                _buildInfoSection(
                  context,
                  'Thông tin liên hệ',
                  Icons.contact_phone_rounded,
                  AppColors.accentPurple,
                  isDark,
                  [
                    _buildInfoRow(
                      Icons.phone_rounded,
                      'Số ĐT',
                      (household.phone != null && household.phone!.isNotEmpty)
                          ? household.phone!
                          : '—',
                    ),
                    _buildInfoRow(
                      Icons.email_rounded,
                      'Email',
                      (household.email != null && household.email!.isNotEmpty)
                          ? household.email!
                          : '—',
                    ),
                    _buildInfoRow(
                      Icons.groups_rounded,
                      'Số thành viên',
                      household.population?.toString() ?? '—',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Location Card
                _buildInfoSection(
                  context,
                  'Vị trí',
                  Icons.map_rounded,
                  AppColors.secondary,
                  isDark,
                  [
                    _buildInfoRow(
                      Icons.pin_drop_rounded,
                      'Kinh độ',
                      household.longitude?.toString() ?? '—',
                    ),
                    _buildInfoRow(
                      Icons.pin_drop_rounded,
                      'Vĩ độ',
                      household.latitude?.toString() ?? '—',
                    ),
                    if (household.longitude != null &&
                        household.latitude != null)
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
                                SnackBar(
                                  content: const Text('Đã sao chép tọa độ'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Sao chép tọa độ'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withAlpha(80),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Notes Card
                if (household.notes != null && household.notes!.isNotEmpty)
                  _buildInfoSection(
                    context,
                    'Ghi chú',
                    Icons.notes_rounded,
                    AppColors.secondary,
                    isDark,
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          household.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Related Incidents Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
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
                    icon: const Icon(Icons.list_alt_rounded, size: 22),
                    label: const Text('Xem sự vụ liên quan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
    IconData icon,
    Color accentColor,
    bool isDark,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withAlpha(80)
              : AppColors.borderLight.withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: AppColors.divider, height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
