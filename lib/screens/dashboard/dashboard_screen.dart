import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_detail_panel.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/population_density_chart.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_comparison.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/overview_statistics_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _viewModeController;
  int _selectedView = 0; // 0 = Dashboard, 1 = Map
  String _chartMetric = 'density';

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

      provinceProvider.loadData().then((_) {
        if (!mounted) return;
        weatherProvider.loadRegionalSummaries(provinceProvider.provinces);
      });
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

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _selectedView == 0
              ? _buildDashboardView()
              : _buildMapView(isMobile: true),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedView,
          onTap: (index) {
            setState(() {
              _selectedView = index;
            });
          },
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Bảng điều khiển',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Bản Đồ',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── LEFT SIDEBAR (Redesigned) ──
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.navBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // App Logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'VN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Dashboard Button
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _selectedView == 0,
                  onTap: () => setState(() => _selectedView = 0),
                ),
                const SizedBox(height: 8),
                // Map Button
                _buildSidebarItem(
                  icon: Icons.map_rounded,
                  label: 'Bản Đồ',
                  isSelected: _selectedView == 1,
                  onTap: () => setState(() => _selectedView = 1),
                ),
                const Spacer(),
                // Theme Toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          themeProvider.toggleTheme();
                          setState(() {});
                        },
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        splashRadius: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // MAIN CONTENT
          Expanded(
            child: _selectedView == 0
                ? _buildDashboardView()
                : _buildMapView(isMobile: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
            color: AppColors.surfaceBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bảng phân tích dữ liệu Việt Nam",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phân tích dân số, diện tích và mật độ 34 tỉnh/thành phố',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Consumer<ProvinceProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.provinces.length} tỉnh/thành phố',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── KPI Cards Row ──
                Consumer<ProvinceProvider>(
                  builder: (context, provider, child) {
                    return _buildKPIRow(provider);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Content Section ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Bar with Icons
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3,
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
                          icon: Icon(
                            _chartMetric == 'density'
                                ? Icons.density_small
                                : _chartMetric == 'area'
                                ? Icons.straighten
                                : Icons.people,
                            size: 18,
                          ),
                          text: _chartMetric == 'density'
                              ? 'Mật Độ Dân Số'
                              : _chartMetric == 'area'
                              ? 'Diện Tích'
                              : 'Dân Số',
                        ),
                        const Tab(
                          icon: Icon(Icons.compare_arrows, size: 18),
                          text: 'So Sánh',
                        ),
                        const Tab(
                          icon: Icon(Icons.insights, size: 18),
                          text: 'Tổng Quan',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                        const OverviewStatisticsTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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

    // Find highest density province
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
          value: '${provinces.length}',
          label: 'Tỉnh/TP',
          icon: Icons.location_city,
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        const SizedBox(width: 16),
        _buildKPI(
          value: _formatCompact(totalPopulation),
          label: 'Tổng dân số',
          icon: Icons.people_alt,
          gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
        ),
        const SizedBox(width: 16),
        _buildKPI(
          value: _formatCompact(avgDensity.toInt()),
          label: 'Mật độ TB',
          icon: Icons.density_medium,
          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
        ),
        const SizedBox(width: 16),
        _buildKPI(
          value: highestName.isNotEmpty
              ? '${_formatCompact(highestValue.toInt())}'
              : '-',
          label: 'Cao nhất: $highestName',
          icon: Icons.arrow_upward,
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        const SizedBox(width: 16),
        _buildKPI(
          value: lowestName.isNotEmpty
              ? '${_formatCompact(lowestValue.toInt())}'
              : '-',
          label: 'Thấp nhất: $lowestName',
          icon: Icons.arrow_downward,
          gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
      ],
    );
  }

  Widget _buildKPI({
    required String value,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
              // MAP (takes full screen)
              Container(
                color: AppColors.mapBackground,
                child: const VietnamMap(),
              ),
              // Back Button if focused
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
              // Bottom Sheet Detail Panel (Native styled overlay)
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
                        // Drag Indicator & Close Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.selectedCommune != null
                                    ? "Chi Tiết Xã/Phường"
                                    : "Chi Tiết Tỉnh",
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
                                  provider
                                      .clearSelection(); // chỉ đóng panel, không thoát focus
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
                          ? "Chi Tiết Xã/Phường"
                          : "Chi Tiết Tỉnh",
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
