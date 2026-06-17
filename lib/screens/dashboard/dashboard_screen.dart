import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

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
        backgroundColor: const Color(0xff0f172a),
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
          backgroundColor: const Color(0xff1e293b),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Text('📊', style: TextStyle(fontSize: 20)),
              label: 'Bảng điều khiển',
            ),
            BottomNavigationBarItem(
              icon: Text('🗺️', style: TextStyle(fontSize: 20)),
              label: 'Bản Đồ',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      body: Row(
        children: [
          // LEFT SIDEBAR
          Container(
            width: 80,
            color: const Color(0xff1e293b),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Dashboard Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedView = 0;
                    });
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedView == 0
                          ? Colors.blue
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          'Bảng điều khiển',
                          style: TextStyle(
                            color: _selectedView == 0
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Map Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedView = 1;
                    });
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedView == 1
                          ? Colors.blue
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🗺️', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          'Bản Đồ',
                          style: TextStyle(
                            color: _selectedView == 1
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildDashboardView() {
    return Container(
      color: const Color(0xff1e293b),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bảng phân tích dữ liệu Việt Nam",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Tab Bar for Analytics
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: _chartMetric == 'density'
                      ? 'Mật Độ Dân Số'
                      : _chartMetric == 'area'
                          ? 'Diện Tích'
                          : 'Dân Số',
                ),
                const Tab(text: 'So Sánh Tỉnh'),
                const Tab(text: 'Tổng Quan & Thống Kê'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.blue,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          const SizedBox(height: 20),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Population Density Chart
                PopulationDensityChart(
                  onMetricChanged: (metric) {
                    setState(() {
                      _chartMetric = metric;
                    });
                  },
                ),
                // Tab 2: Province Comparison
                Consumer<ProvinceProvider>(
                  builder: (context, provider, child) {
                    return ProvinceComparison(provinces: provider.provinces);
                  },
                ),
                // Tab 3: Overview & Statistics
                const OverviewStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView({required bool isMobile}) {
    if (isMobile) {
      return Consumer<ProvinceProvider>(
        builder: (context, provider, child) {
          final showDetails = provider.selectedProvince != null ||
              provider.selectedCommune != null;

          return Stack(
            children: [
              // MAP (takes full screen)
              Container(
                color: Colors.blueGrey,
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
                      backgroundColor: const Color(0xff1e293b),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("← Quay lại", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    decoration: const BoxDecoration(
                      color: Color(0xff1e293b),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 15,
                          offset: Offset(0, -3),
                        )
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
                                    ? "Chi Tiết Xã"
                                    : "Chi Tiết Tỉnh",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: () {
                                  provider.clearSelection(); // chỉ đóng panel, không thoát focus
                                },
                              )
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        Expanded(
                          child: ProvinceDetailPanel(
                            province: provider.selectedCommune ??
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
            color: Colors.blueGrey,
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
            color: const Color(0xff1e293b),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chi Tiết Tỉnh",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Consumer<ProvinceProvider>(
                    builder: (context, provider, child) {
                      return ProvinceDetailPanel(
                        province: provider.selectedCommune ??
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
