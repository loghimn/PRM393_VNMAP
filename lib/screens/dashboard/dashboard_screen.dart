import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_detail_panel.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/population_density_chart.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_comparison.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/overview_statistics_tab.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_list_panel.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/khu_pho/khu_pho_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/statistics/statistics_screen.dart';
import 'package:vietnam_geo_dashboard/screens/auth/profile_screen.dart';
import 'package:vietnam_geo_dashboard/screens/lich_su/dia_diem_lich_su_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _viewModeController;
  int _selectedView =
      0; // 0 = Dashboard, 1 = Map, 2 = Household, 3 = Incident, 4 = Khu phố (admin), 5 = Di tích (admin), 6 = Thống kê (admin), 7 = Profile
  String _chartMetric = 'density';
  int? _hoveredSidebarItem;
  bool _isKPIExpanded = true;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModeController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provinceProvider = context.read<ProvinceProvider>();
      final weatherProvider = context.read<WeatherProvider>();
      final statsProvider = context.read<StatisticsProvider>();
      provinceProvider.loadData().then((_) {
        if (!mounted) return;
        weatherProvider.loadRegionalSummaries(provinceProvider.provinces);
      });
      statsProvider.loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _buildMainContent(isMobile: true)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _getVisibleIndex(_selectedView, isAdmin),
          onDestinationSelected: (index) {
            setState(() {
              _selectedView = _getSelectionForVisibleIndex(index, isAdmin);
            });
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withAlpha(30),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Tổng quan',
            ),
            const NavigationDestination(
              icon: Icon(Icons.map_rounded),
              label: 'Bản đồ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.home_work_rounded),
              label: 'Hộ gia đình',
            ),
            const NavigationDestination(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Sự vụ',
            ),
            if (isAdmin) ...[
              const NavigationDestination(
                icon: Icon(Icons.apartment_rounded),
                label: 'Khu phố',
              ),
              const NavigationDestination(
                icon: Icon(Icons.history_edu_rounded),
                label: 'Di tích',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Thống kê',
              ),
            ],
            const NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Tài khoản',
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── LEFT SIDEBAR (Collapsible) ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: _isSidebarExpanded ? 72 : 0,
            decoration: BoxDecoration(
              color: AppColors.navBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _isSidebarExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 24),
                      // App Logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'VN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Dashboard Button
                      _buildSidebarItem(
                        index: 0,
                        icon: Icons.dashboard_rounded,
                        label: 'Tổng quan',
                        isSelected: _selectedView == 0,
                        onTap: () => setState(() => _selectedView = 0),
                      ),
                      const SizedBox(height: 6),
                      // Map Button
                      _buildSidebarItem(
                        index: 1,
                        icon: Icons.map_rounded,
                        label: 'Bản đồ',
                        isSelected: _selectedView == 1,
                        onTap: () => setState(() => _selectedView = 1),
                      ),
                      const SizedBox(height: 6),
                      _buildSidebarItem(
                        index: 2,
                        icon: Icons.home_work_rounded,
                        label: 'Hộ gia đình',
                        isSelected: _selectedView == 2,
                        onTap: () => setState(() => _selectedView = 2),
                      ),
                      const SizedBox(height: 6),
                      _buildSidebarItem(
                        index: 3,
                        icon: Icons.warning_amber_rounded,
                        label: 'Sự vụ',
                        isSelected: _selectedView == 3,
                        onTap: () => setState(() => _selectedView = 3),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 6),
                        _buildSidebarItem(
                          index: 4,
                          icon: Icons.apartment_rounded,
                          label: 'Khu phố',
                          isSelected: _selectedView == 4,
                          onTap: () => setState(() => _selectedView = 4),
                        ),
                        const SizedBox(height: 6),
                        _buildSidebarItem(
                          index: 5,
                          icon: Icons.history_edu_rounded,
                          label: 'Di tích',
                          isSelected: _selectedView == 5,
                          onTap: () => setState(() => _selectedView = 5),
                        ),
                        const SizedBox(height: 6),
                        _buildSidebarItem(
                          index: 6,
                          icon: Icons.bar_chart_rounded,
                          label: 'Thống kê',
                          isSelected: _selectedView == 6,
                          onTap: () => setState(() => _selectedView = 6),
                        ),
                      ],
                      const SizedBox(height: 6),
                      _buildSidebarItem(
                        index: 7,
                        icon: Icons.person_rounded,
                        label: 'Tài khoản',
                        isSelected: _selectedView == 7,
                        onTap: () => setState(() => _selectedView = 7),
                      ),
                      const Spacer(),
                      // Sidebar Collapse Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSidebarExpanded = false;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.3),
                            ),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Theme Toggle
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: IconButton(
                              onPressed: () {
                                themeProvider.toggleTheme();
                                setState(() {});
                              },
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  key: ValueKey(themeProvider.isDarkMode),
                                  themeProvider.isDarkMode
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              splashRadius: 18,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // Collapsed Sidebar Toggle Button (floating on the edge)
          if (!_isSidebarExpanded)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSidebarExpanded = true;
                });
              },
              child: Container(
                width: 24,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navBackground,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          // MAIN CONTENT
          Expanded(child: _buildMainContent(isMobile: false)),
        ],
      ),
    );
  }

  int _getVisibleIndex(int selectedView, bool isAdmin) {
    if (isAdmin) return selectedView;
    switch (selectedView) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 7:
        return 4;
      default:
        return 0;
    }
  }

  int _getSelectionForVisibleIndex(int visibleIndex, bool isAdmin) {
    if (isAdmin) return visibleIndex;
    switch (visibleIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 6;
      case 5:
        return 7;
      default:
        return 0;
    }
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredSidebarItem == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSidebarItem = index),
      onExit: (_) => setState(() => _hoveredSidebarItem = null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isHovered && !isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : isHovered
                  ? AppColors.hoverBg
                  : AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : isHovered
                  ? AppColors.cardShadow
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    switch (_selectedView) {
      case 0:
        return _buildDashboardView();
      case 1:
        return _buildMapView(isMobile: isMobile);
      case 2:
        return const HouseholdListScreen();
      case 3:
        return const IncidentListScreen();
      case 4:
        return const KhuPhoListScreen();
      case 5:
        return const DiaDiemLichSuListScreen();
      case 6:
        return const StatisticsScreen();
      case 7:
        return const ProfileScreen();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Very Compact) ──
          Container(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 6),
            color: AppColors.surfaceBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row - small
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bảng Điều Khiển Dữ Liệu Việt Nam",
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Phân tích dân số, diện tích và mật độ 34 tỉnh/thành phố',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // ── Toggle row ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isKPIExpanded = !_isKPIExpanded;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: _isKPIExpanded
                              ? AppColors.primaryGradient
                              : null,
                          color: _isKPIExpanded
                              ? null
                              : AppColors.surfaceBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isKPIExpanded
                                ? Colors.transparent
                                : AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isKPIExpanded
                                  ? Icons.bar_chart_rounded
                                  : Icons.format_list_bulleted_rounded,
                              size: 10,
                              color: _isKPIExpanded
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isKPIExpanded
                                  ? 'Thống kê nhanh'
                                  : 'Danh sách Tỉnh/TP',
                              style: TextStyle(
                                color: _isKPIExpanded
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isKPIExpanded = !_isKPIExpanded;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: _isKPIExpanded ? 0.0 : 0.5,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Consumer<ProvinceProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.provinces.length} tỉnh/thành phố',
                          style: AppTypography.small.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // ── KPI Cards or Province List ──
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _isKPIExpanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Consumer<ProvinceProvider>(
                    builder: (context, provider, child) {
                      return _buildKPIRow(provider);
                    },
                  ),
                  secondChild: Container(
                    height: 140,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(AppColors.cardRadius),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ProvinceListPanel(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Content Section ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Bar - compact
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.2),
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicator: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.all(3),
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _chartMetric == 'density'
                                      ? Icons.density_small
                                      : _chartMetric == 'area'
                                      ? Icons.straighten
                                      : Icons.people,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _chartMetric == 'density'
                                      ? 'Mật Độ Dân Số'
                                      : _chartMetric == 'area'
                                      ? 'Diện tích'
                                      : 'Dân số',
                                ),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.compare_arrows, size: 12),
                                SizedBox(width: 4),
                                Text('So sánh'),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.insights, size: 12),
                                SizedBox(width: 4),
                                Text('Tổng quan'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        PopulationDensityChart(
                          onMetricChanged: (metric) {
                            setState(() {
                              _chartMetric = metric;
                            });
                          },
                        ),
                        Consumer<ProvinceProvider>(
                          builder: (context, provider, child) {
                            return ProvinceComparison(
                              provinces: provider.provinces,
                            );
                          },
                        ),
                        OverviewStatisticsTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentStatsTab() {
    return Consumer<StatisticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.loadAll(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildMonthChart(provider),
              const SizedBox(height: 16),
              _buildNeighborhoodChart(provider),
              const SizedBox(height: 16),
              _buildStatusChart(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthChart(StatisticsProvider provider) {
    final data = provider.incidentsByMonth;
    if (data.isEmpty) return const SizedBox();
    return Card(
      color: AppColors.surfaceBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Theo tháng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                DropdownButton<int>(
                  value: provider.selectedYear,
                  dropdownColor: const Color(0xff334155),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: DateTime.now().year - i,
                      child: Text('${DateTime.now().year - i}'),
                    ),
                  ),
                  onChanged: (year) {
                    if (year != null) {
                      provider.setSelectedYear(year);
                      provider.loadByMonth();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.values.isNotEmpty
                      ? data.values.reduce((a, b) => a > b ? a : b).toDouble() +
                            2
                      : 10,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Tháng ${group.x}\n${rod.toY.toInt()} sự vụ',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => value % 2 == 0
                            ? Text(
                                'T${value.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 9,
                                ),
                              )
                            : const SizedBox(),
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.entries.map((entry) {
                    final month =
                        int.tryParse(entry.key.replaceAll('Month ', '')) ?? 1;
                    return BarChartGroupData(
                      x: month,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.blue.shade400,
                          width: 14,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeighborhoodChart(StatisticsProvider provider) {
    final data = provider.incidentsByNeighborhood;
    if (data.isEmpty) return const SizedBox();
    final maxValue = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 1;
    return Card(
      color: AppColors.surfaceBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo khu phố',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxValue > 0 ? entry.value / maxValue : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(StatisticsProvider provider) {
    final data = provider.incidentsByStatus;
    if (data.isEmpty) return const SizedBox();
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    return Card(
      color: AppColors.surfaceBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo trạng thái',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (total > 0)
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: data.entries.map((entry) {
                      Color color;
                      switch (entry.key) {
                        case 'Received':
                          color = Colors.blue;
                          break;
                        case 'Processing':
                          color = Colors.orange;
                          break;
                        case 'Completed':
                          color = Colors.green;
                          break;
                        case 'Cancelled':
                          color = Colors.red;
                          break;
                        default:
                          color = Colors.grey;
                      }
                      return PieChartSectionData(
                        color: color,
                        value: entry.value.toDouble(),
                        title:
                            '${(entry.value / total * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ...data.entries.map((entry) {
              Color color;
              switch (entry.key) {
                case 'Received':
                  color = Colors.blue;
                  break;
                case 'Processing':
                  color = Colors.orange;
                  break;
                case 'Completed':
                  color = Colors.green;
                  break;
                case 'Cancelled':
                  color = Colors.red;
                  break;
                default:
                  color = Colors.grey;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      total > 0
                          ? '(${(entry.value / total * 100).toStringAsFixed(1)}%)'
                          : '',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIRow(ProvinceProvider provider) {
    final provinces = provider.provinces;
    if (provinces.isEmpty) return const SizedBox.shrink();
    double totalPopulation = 0;
    double totalArea = 0;
    for (final p in provinces) {
      totalPopulation += (p.population ?? 0);
      totalArea += (p.areaKm2 ?? 0);
    }
    final avgDensity = totalArea > 0 ? totalPopulation / totalArea : 0;
    String highestName = '';
    double highestValue = 0;
    String lowestName = '';
    double lowestValue = double.infinity;
    for (final p in provinces) {
      final d = p.density ?? 0;
      if (d > highestValue) {
        highestValue = d;
        highestName = p.name;
      }
      if (d < lowestValue && d > 0) {
        lowestValue = d;
        lowestName = p.name;
      }
    }
    return Row(
      children: [
        _buildKPI(
          icon: Icons.location_city_rounded,
          value: '${provinces.length}',
          label: 'Tỉnh/TP',
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          trend: '+0%',
        ),
        const SizedBox(width: 8),
        _buildKPI(
          icon: Icons.people_rounded,
          value: _formatCompact(totalPopulation),
          label: 'Tổng dân số',
          gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
          sublabel: 'Toàn quốc',
        ),
        const SizedBox(width: 8),
        _buildKPI(
          icon: Icons.density_small_rounded,
          value: _formatCompact(avgDensity.toInt()),
          label: 'Mật độ TB',
          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          sublabel: 'người/km\u00b2',
        ),
        const SizedBox(width: 8),
        _buildKPI(
          icon: Icons.arrow_upward_rounded,
          value: highestName.isNotEmpty
              ? _formatCompact(highestValue.toInt())
              : '-',
          label: 'Cao nhất: $highestName',
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          badge: '🏆',
        ),
        const SizedBox(width: 8),
        _buildKPI(
          icon: Icons.arrow_downward_rounded,
          value: lowestName.isNotEmpty
              ? _formatCompact(lowestValue.toInt())
              : '-',
          label: 'Thấp nhất: $lowestName',
          gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
          badge: '📍',
        ),
      ],
    );
  }

  Widget _buildKPI({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradientColors,
    String? sublabel,
    String? trend,
    String? badge,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 12),
                ),
                if (badge != null)
                  Text(badge, style: const TextStyle(fontSize: 12)),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (sublabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  sublabel,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCompact(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildMapView({required bool isMobile}) {
    if (isMobile) {
      return Consumer<ProvinceProvider>(
        builder: (context, provider, child) {
          final showDetails =
              provider.selectedProvince != null ||
              provider.selectedCommune != null;
          return Stack(
            children: [
              Container(
                color: AppColors.mapBackground,
                child: const VietnamMap(),
              ),
              if (provider.focusedProvince != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.clearFocus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "← Quay lại",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (showDetails)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 15,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.selectedCommune != null
                                    ? "Chi tiết phường/xã"
                                    : "Chi tiết tỉnh/thành phố",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  provider.clearSelection();
                                },
                              ),
                            ],
                          ),
                        ),
                        Divider(color: AppColors.divider, height: 1),
                        Expanded(
                          child: ProvinceDetailPanel(
                            province:
                                provider.selectedCommune ??
                                provider.selectedProvince,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
    return Row(
      children: [
        // MAP (Main)
        Expanded(
          flex: 6,
          child: Container(
            color: AppColors.mapBackground,
            child: Stack(
              children: [
                const VietnamMap(),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Consumer<ProvinceProvider>(
                    builder: (context, provider, child) {
                      if (provider.focusedProvince == null) {
                        return const SizedBox();
                      }
                      return ElevatedButton(
                        onPressed: () {
                          provider.clearFocus();
                        },
                        child: const Text("← Quay lại"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // PROVINCE DETAILS (Right Panel)
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.navBackground,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<ProvinceProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      provider.selectedCommune != null
                          ? "Chi tiết phường/xã"
                          : "Chi tiết tỉnh/thành phố",
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Consumer<ProvinceProvider>(
                    builder: (context, provider, child) {
                      return ProvinceDetailPanel(
                        province:
                            provider.selectedCommune ??
                            provider.selectedProvince,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
