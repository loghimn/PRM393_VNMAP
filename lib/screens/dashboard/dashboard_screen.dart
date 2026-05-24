import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_detail_panel.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/population_density_chart.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_comparison.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                    height: 70,
                    decoration: BoxDecoration(
                      color: _selectedView == 0
                          ? Colors.blue
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          'Dashboard',
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
                    height: 70,
                    decoration: BoxDecoration(
                      color: _selectedView == 1
                          ? Colors.blue
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🗺️', style: TextStyle(fontSize: 32)),
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
            child: _selectedView == 0 ? _buildDashboardView() : _buildMapView(),
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
            "Vietnam Analytics Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Tab Bar for Analytics
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Mật Độ Dân Số'),
                Tab(text: 'So Sánh Tỉnh'),
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
                Consumer<ProvinceProvider>(
                  builder: (context, provider, child) {
                    return PopulationDensityChart(
                      provinces: provider.provinces,
                    );
                  },
                ),
                // Tab 2: Province Comparison
                Consumer<ProvinceProvider>(
                  builder: (context, provider, child) {
                    return ProvinceComparison(provinces: provider.provinces);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
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
                        child: const Text("← Back"),
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
