import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_request_provider.dart';
import '../../utils/app_theme.dart';
import 'household_request_detail_screen.dart';

class HouseholdRequestListScreen extends StatefulWidget {
  const HouseholdRequestListScreen({super.key});

  @override
  State<HouseholdRequestListScreen> createState() =>
      _HouseholdRequestListScreenState();
}

class _HouseholdRequestListScreenState extends State<HouseholdRequestListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdRequestProvider>().fetchAllRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == 'admin';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Yêu cầu tạo hộ'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                'Chỉ admin mới có quyền truy cập',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yêu cầu tạo hộ gia đình'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Từ chối'),
          ],
        ),
      ),
      body: Consumer<HouseholdRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(provider.pendingRequests, provider),
              _buildRequestList(provider.approvedRequests, provider),
              _buildRequestList(provider.rejectedRequests, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestList(
    List<dynamic> requests,
    HouseholdRequestProvider provider,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchAllRequests(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return _buildRequestCard(req);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final status = request.status as String? ?? 'pending';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Từ chối';
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = 'Chờ duyệt';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surfaceBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withAlpha(80)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HouseholdRequestDetailScreen(requestId: request.id as int),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.headOfHousehold as String? ?? 'N/A',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildAddress(request),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMutedDark,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildAddress(dynamic request) {
    final parts = <String>[
      if (request.houseNumber != null &&
          (request.houseNumber as String).isNotEmpty)
        request.houseNumber as String,
      if (request.street != null && (request.street as String).isNotEmpty)
        request.street as String,
      if (request.ward != null && (request.ward as String).isNotEmpty)
        request.ward as String,
      if (request.district != null && (request.district as String).isNotEmpty)
        request.district as String,
      if (request.city != null && (request.city as String).isNotEmpty)
        request.city as String,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Chưa có địa chỉ';
  }
}
