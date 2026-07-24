import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_request_provider.dart';
import '../../models/household_model.dart';
import '../../models/household_request_model.dart';
import '../../utils/app_theme.dart';
import 'household_detail_screen.dart';
import 'household_request_form_screen.dart';

class HouseholdListScreen extends StatefulWidget {
  const HouseholdListScreen({super.key});

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends State<HouseholdListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  Household? _userHousehold;
  bool _isLoadingPhone = false;
  HouseholdRequest? _pendingRequest;
  bool _isCheckingRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final isAdmin = auth.isAdmin;
      if (isAdmin) {
        context.read<HouseholdProvider>().loadItems();
      } else {
        _loadUserHouseholdByPhone();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserHouseholdByPhone() async {
    final auth = context.read<AuthProvider>();
    final userPhone = auth.currentUser?.phone;
    final userId = auth.currentUser?.id;
    if (userPhone == null || userPhone.isEmpty) {
      return;
    }

    setState(() => _isLoadingPhone = true);

    try {
      final provider = context.read<HouseholdProvider>();
      final found = await provider.searchByPhone(userPhone);
      if (found != null) {
        setState(() => _userHousehold = found);
      } else {
        await provider.loadItems(createdBy: auth.currentUser?.id);
        if (provider.items.isNotEmpty) {
          setState(() => _userHousehold = provider.items.first);
        } else {
          setState(() => _userHousehold = null);
        }
      }

      // Check if user has any pending request
      if (userId != null && _userHousehold == null) {
        setState(() => _isCheckingRequest = true);
        final reqProvider = context.read<HouseholdRequestProvider>();
        final pending = await reqProvider.getUserPendingRequest(userId);
        setState(() => _pendingRequest = pending);
      } else {
        setState(() => _pendingRequest = null);
      }
    } catch (e) {
      setState(() => _userHousehold = null);
    } finally {
      setState(() {
        _isLoadingPhone = false;
        _isCheckingRequest = false;
      });
    }
  }

  void _onSearch(String query) {
    context.read<HouseholdProvider>().loadItems(searchQuery: query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Thông tin hộ gia đình'),
          backgroundColor: AppColors.surfaceBackground,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: _buildUserHouseholdView(isDark: isDark),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm hộ gia đình...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: _onSearch,
              )
            : Text(
                'Danh sách hộ gia đình',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearching),
                color: AppColors.textSecondary,
              ),
            ),
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
                      onPressed: () => provider.loadItems(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.items.isEmpty) {
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
                    'Chưa có hộ gia đình nào',
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

          return RefreshIndicator(
            onRefresh: () => provider.loadItems(),
            color: AppColors.primary,
            child: Column(
              children: [
                if (provider.isLoading)
                  LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: AppColors.primary.withAlpha(20),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: provider.items.length,
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return _buildHouseholdCard(item, index, isDark, theme);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHouseholdCard(
    Household item,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    final provider = context.read<HouseholdProvider>();
    final colors = [
      AppColors.primary,
      AppColors.accentPurple,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
    ];
    final accentColor = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseholdDetailScreen(householdId: item.id!),
              ),
            );
          },
          child: Container(
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
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppColors.cardRadius),
                        bottomLeft: Radius.circular(AppColors.cardRadius),
                      ),
                    ),
                  ),
                  // Avatar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: accentColor.withAlpha(25),
                      child: Text(
                        item.headOfHousehold.isNotEmpty
                            ? item.headOfHousehold[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.headOfHousehold,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.householdCode,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              if (item.population != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.groups_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${item.population} người',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (item.fullAddress.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.fullAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Xác nhận xóa'),
                            content: Text(
                              'Bạn có chắc chắn muốn xóa hộ gia đình "${item.headOfHousehold}" không?',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'Hủy',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && item.id != null) {
                          await provider.delete(item.id!);
                        }
                      }
                    },
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.surfaceBackground,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Xóa',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHouseholdView({required bool isDark}) {
    if (_isLoadingPhone) {
      return const Center(child: CircularProgressIndicator());
    }

    final household = _userHousehold;
    if (household == null) {
      // Show pending request status
      if (_isCheckingRequest) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_pendingRequest != null) {
        final req = _pendingRequest!;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 72,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Đã gửi yêu cầu tạo hộ gia đình',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Yêu cầu của bạn đang chờ admin phê duyệt.\nThông tin đã gửi:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Request info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withAlpha(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMiniInfoRow(
                        Icons.person_rounded,
                        'Chủ hộ',
                        req.headOfHousehold,
                      ),
                      const SizedBox(height: 8),
                      _buildMiniInfoRow(
                        Icons.phone_rounded,
                        'Số ĐT',
                        req.phone,
                      ),
                      if (req.fullAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildMiniInfoRow(
                          Icons.location_on_rounded,
                          'Địa chỉ',
                          req.fullAddress,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Trạng thái: Đang chờ duyệt',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // No household and no pending request → show create request button
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  size: 72,
                  color: AppColors.textSecondary.withAlpha(120),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chưa có thông tin hộ gia đình',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Số điện thoại của bạn chưa được liên kết\nvới hộ gia đình nào.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HouseholdRequestFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text(
                    'Gửi yêu cầu tạo hộ gia đình',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
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
          // Address Information
          _buildInfoCard(
            title: 'Thông tin địa chỉ',
            icon: Icons.location_on_rounded,
            accentColor: AppColors.primary,
            isDark: isDark,
            children: [
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
          // Contact Information
          _buildInfoCard(
            title: 'Thông tin liên hệ',
            icon: Icons.contact_phone_rounded,
            accentColor: AppColors.accentPurple,
            isDark: isDark,
            children: [
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
          if (household.notes != null && household.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              title: 'Ghi chú',
              icon: Icons.notes_rounded,
              accentColor: AppColors.secondary,
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
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
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required List<Widget> children,
  }) {
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

  Widget _buildMiniInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
