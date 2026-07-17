import 'dart:math';
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
      0; // 0 = Dashboard, 1 = Map, 2 = Household, 3 = Incident, 4 = Khu phố (admin), 5 = Di tích, 6 = Profile
  String _chartMetric = 'density';
  int? _hoveredSidebarItem;
  bool _isKPIExpanded = true;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _viewModeController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isAdmin && _selectedView == 0) {
        setState(() {
          _selectedView = 1;
        });
      }

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
        bottomNavigationBar: _buildBottomNavigation(isAdmin),
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
                      const SizedBox(height: 16),
                      // Scrollable navigation items
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Dashboard Button
                              if (isAdmin) ...[
                                _buildSidebarItem(
                                  index: 0,
                                  icon: Icons.dashboard_rounded,
                                  label: 'Tổng quan',
                                  isSelected: _selectedView == 0,
                                  onTap: () => setState(() => _selectedView = 0),
                                ),
                                const SizedBox(height: 6),
                              ],
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
                                  onTap: () =>
                                      setState(() => _selectedView = 4),
                                ),
                              ],
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
                                icon: Icons.person_rounded,
                                label: 'Tài khoản',
                                isSelected: _selectedView == 6,
                                onTap: () => setState(() => _selectedView = 6),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
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
      case 1:
        return 0;
      case 2:
        return 1;
      case 3:
        return 2;
      case 5:
        return 3;
      case 6:
        return 4;
      default:
        return 0;
    }
  }

  int _getSelectionForVisibleIndex(int visibleIndex, bool isAdmin) {
    if (isAdmin) return visibleIndex;
    switch (visibleIndex) {
      case 0:
        return 1;
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 5;
      case 4:
        return 6;
      default:
        return 1;
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
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final activeView = (!isAdmin && _selectedView == 0) ? 1 : _selectedView;

    switch (activeView) {
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
        return const ProfileScreen();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildBottomNavigation(bool isAdmin) {
    final navItems = _buildNavItems(isAdmin);
    final navHeight = isAdmin ? 80.0 : 72.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navHeight,
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.primary.withAlpha(25),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  // Same TextStyle for both states to prevent text shift
                  return TextStyle(
                    color: states.contains(WidgetState.selected)
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: AppColors.primary,
                      size: 22,
                    );
                  }
                  return IconThemeData(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    size: 20,
                  );
                }),
                elevation: 0,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                height: navHeight,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
            child: NavigationBar(
              key: ValueKey(isAdmin),
              selectedIndex: _getVisibleIndex(_selectedView, isAdmin),
              onDestinationSelected: (index) {
                setState(() {
                  _selectedView = _getSelectionForVisibleIndex(index, isAdmin);
                });
              },
              animationDuration: Duration.zero,
              destinations: navItems,
            ),
          ),
        ),
      ),
    );
  }

  List<NavigationDestination> _buildNavItems(bool isAdmin) {
    final items = <NavigationDestination>[];
    void addItem(IconData icon, String label) {
      items.add(
        NavigationDestination(
          icon: Icon(icon, size: 20),
          selectedIcon: Icon(icon, size: 22),
          label: label,
        ),
      );
    }

    if (isAdmin) {
      addItem(Icons.dashboard_rounded, 'Tổng quan');
    }
    addItem(Icons.map_rounded, 'Bản đồ');
    addItem(Icons.home_work_rounded, 'Hộ gia đình');
    addItem(Icons.warning_amber_rounded, 'Sự vụ');
    if (isAdmin) {
      addItem(Icons.apartment_rounded, 'Khu phố');
    }
    addItem(Icons.history_edu_rounded, 'Di tích');
    addItem(Icons.person_rounded, 'Tài khoản');
    return items;
  }

  Widget _buildDashboardView() {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _buildHeader(),
          // ── KPI Row (Separated) ──
          Consumer<ProvinceProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _isKPIExpanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: _buildKPIRow(provider),
                  secondChild: Container(
                    height: 140,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(AppColors.cardRadius),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: ProvinceListPanel(),
                  ),
                ),
              );
            },
          ),
          // ── Content Section ──
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab Bar
                      _buildTabBar(),
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
                            _buildIncidentStatsTab(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final hPad = isMobile ? 12.0 : 32.0;
        return Container(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Bảng Dữ Liệu Việt Nam",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: isMobile ? 24 : 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '34 tỉnh/thành phố',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: isMobile ? 13 : 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick stats toggle dropdown
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isKPIExpanded = !_isKPIExpanded;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: _isKPIExpanded
                            ? AppColors.primaryGradient
                            : null,
                        color: _isKPIExpanded
                            ? null
                            : AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(999),
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
                            size: 13,
                            color: _isKPIExpanded
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _isKPIExpanded ? 'Thống kê' : 'Danh sách',
                              style: TextStyle(
                                color: _isKPIExpanded
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: _isKPIExpanded ? 0.0 : 0.5,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 13,
                              color: _isKPIExpanded
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TabBar(
          isScrollable: true,
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 4,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
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
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _chartMetric == 'density'
                        ? 'Mật độ'
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
                  Icon(Icons.compare_arrows, size: 14),
                  SizedBox(width: 6),
                  Text('So sánh'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights, size: 14),
                  SizedBox(width: 6),
                  Text('Tổng quan'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 14),
                  SizedBox(width: 6),
                  Text('Thống kê'),
                ],
              ),
            ),
          ],
        ),
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

        final statusData = provider.incidentsByStatus;
        final total = statusData.values.fold<int>(0, (sum, v) => sum + v);
        final received = statusData['Received'] ?? 0;
        final processing = statusData['Processing'] ?? 0;
        final completed = statusData['Completed'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _buildIncidentKpiCard(
                    title: 'Tổng sự vụ',
                    value: '$total',
                    icon: Icons.assignment_rounded,
                    gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  _buildIncidentKpiCard(
                    title: 'Đã hoàn thành',
                    value: '$completed',
                    icon: Icons.check_circle_rounded,
                    gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  _buildIncidentKpiCard(
                    title: 'Đang xử lý',
                    value: '$processing',
                    icon: Icons.sync_rounded,
                    gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  _buildIncidentKpiCard(
                    title: 'Đang chờ',
                    value: '$received',
                    icon: Icons.hourglass_empty_rounded,
                    gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                  ),
                ],
              ),
              const SizedBox(height: 16),
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

  Widget _buildIncidentKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withAlpha(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(StatisticsProvider provider) {
    final data = provider.incidentsByMonth;
    if (data.isEmpty) return const SizedBox();

    final double maxVal = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 10;
    final double maxY = maxVal + (maxVal * 0.15).ceilToDouble(); // give some headroom
    final double interval = maxY > 10 ? (maxY / 5).ceilToDouble() : 2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thống kê theo tháng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: provider.selectedYear,
                    dropdownColor: AppColors.surfaceSubtleDark,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight, size: 18),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY <= 0 ? 10 : maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.surfaceSubtleDark.withAlpha(240),
                    tooltipBorder: BorderSide(color: AppColors.primary.withAlpha(100), width: 1),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Tháng ${group.x}\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} sự vụ',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final intVal = value.toInt();
                        if (intVal >= 1 && intVal <= 12) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'T$intVal',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: interval <= 0 ? 2 : interval,
                      getTitlesWidget: (value, meta) {
                        if (value == value.toInt()) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval <= 0 ? 2 : interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withAlpha(20),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY <= 0 ? 10 : maxY,
                          color: AppColors.border.withAlpha(10),
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
    );
  }

  Widget _buildNeighborhoodChart(StatisticsProvider provider) {
    final data = provider.incidentsByNeighborhood;
    if (data.isEmpty) return const SizedBox();
    final maxValue = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 1;

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int rank = 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê theo khu phố',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final currentRank = rank++;
            
            List<Color> gradientColors;
            if (currentRank == 1) {
              gradientColors = const [Color(0xFFF59E0B), Color(0xFFD97706)];
            } else if (currentRank == 2) {
              gradientColors = const [Color(0xFF94A3B8), Color(0xFF64748B)];
            } else if (currentRank == 3) {
              gradientColors = const [Color(0xFFB45309), Color(0xFF78350F)];
            } else {
              gradientColors = const [Color(0xFF3B82F6), Color(0xFF60A5FA)];
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _buildRankBadge(currentRank),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${entry.value} sự vụ',
                              style: TextStyle(
                                color: currentRank <= 3 
                                    ? gradientColors[0] 
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double pct = maxValue > 0 ? entry.value / maxValue : 0;
                            return Stack(
                              children: [
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.border.withAlpha(20),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Container(
                                  height: 6,
                                  width: constraints.maxWidth * pct,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradientColors[0].withAlpha(60),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 16));
    } else if (rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 16));
    } else if (rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 16));
    }

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.border.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChart(StatisticsProvider provider) {
    final data = provider.incidentsByStatus;
    if (data.isEmpty) return const SizedBox();
    final total = data.values.fold<int>(0, (sum, v) => sum + v);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái xử lý',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                      sections: data.entries.map((entry) {
                        Color color;
                        switch (entry.key) {
                          case 'Received':
                            color = AppColors.primary;
                            break;
                          case 'Processing':
                            color = AppColors.warning;
                            break;
                          case 'Completed':
                            color = AppColors.success;
                            break;
                          case 'Cancelled':
                            color = AppColors.error;
                            break;
                          default:
                            color = Colors.grey;
                        }
                        return PieChartSectionData(
                          color: color,
                          value: entry.value.toDouble(),
                          title: '',
                          radius: 12,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.entries.map((entry) {
                    Color color;
                    String statusLabel;
                    switch (entry.key) {
                      case 'Received':
                        color = AppColors.primary;
                        statusLabel = 'Tiếp nhận';
                        break;
                      case 'Processing':
                        color = AppColors.warning;
                        statusLabel = 'Đang xử lý';
                        break;
                      case 'Completed':
                        color = AppColors.success;
                        statusLabel = 'Đã hoàn thành';
                        break;
                      case 'Cancelled':
                        color = AppColors.error;
                        statusLabel = 'Đã hủy';
                        break;
                      default:
                        color = Colors.grey;
                        statusLabel = entry.key;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            total > 0
                                ? '${(entry.value / total * 100).toStringAsFixed(0)}%'
                                : '0%',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
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

    final kpiData = [
      _KpiData(
        icon: Icons.density_small_rounded,
        value: _formatCompact(avgDensity.toInt()),
        label: 'Mật độ TB',
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
        sublabel: 'người/km\u00b2',
      ),
      _KpiData(
        icon: Icons.arrow_upward_rounded,
        value: highestName.isNotEmpty
            ? _formatCompact(highestValue.toInt())
            : '-',
        label: 'Cao nhất',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        sublabel: highestName,
        badge: '🏆',
      ),
      _KpiData(
        icon: Icons.arrow_downward_rounded,
        value: lowestName.isNotEmpty
            ? _formatCompact(lowestValue.toInt())
            : '-',
        label: 'Thấp nhất',
        gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        sublabel: lowestName,
        badge: '📍',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = max(constraints.maxWidth / 3 - 16, 140.0);
        final List<Widget> kpiChildren = [];
        for (int i = 0; i < kpiData.length; i++) {
          final kpi = kpiData[i];
          final isLast = i == kpiData.length - 1;
          kpiChildren.add(
            Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 16),
              child: _buildKPI(kpi: kpi, width: cardWidth, compact: true),
            ),
          );
        }

        // Always show KPI cards in one horizontal row with scroll if needed
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: kpiChildren),
          ),
        );
      },
    );
  }

  Widget _buildKPI({
    required _KpiData kpi,
    double? width,
    bool compact = false,
  }) {
    final cardValue = compact ? 24.0 : 30.0;
    final cardLabel = compact ? 13.0 : 15.0;
    final cardCaption = compact ? 11.0 : 13.0;
    final vPad = compact ? 10.0 : 16.0;
    final iconSize = compact ? 14.0 : 16.0;
    final iconBox = compact ? 26.0 : 32.0;
    return SizedBox(
      width: width ?? 170,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 110 : 130),
        padding: EdgeInsets.all(vPad),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: kpi.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: kpi.gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(kpi.icon, color: Colors.white, size: iconSize),
                ),
                if (kpi.badge != null)
                  Text(
                    kpi.badge!,
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
              ],
            ),
            // Use a fixed gap instead of Spacer to avoid pushing content
            // into an undersized container which can cause overflow.
            SizedBox(height: compact ? 8.0 : 12.0),
            // Value
            Text(
              kpi.value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: cardValue,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              kpi.label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: cardLabel,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (kpi.sublabel != null && kpi.sublabel!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                kpi.sublabel!,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: cardCaption,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
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

class _KpiData {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradientColors;
  final String? sublabel;
  final String? badge;

  const _KpiData({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradientColors,
    this.sublabel,
    this.badge,
  });
}
