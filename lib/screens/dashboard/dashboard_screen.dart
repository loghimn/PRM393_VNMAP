import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_detail_panel.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/population_density_chart.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      context.read<ProvinceProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),

      body: Row(
        children: [
          // MAP
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

          // ANALYTICS
          Expanded(
            flex: 4,

            child: Container(
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

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white24)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Mật Độ Dân Số'),
                        Tab(text: 'Chi Tiết Tỉnh'),
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

                        // Tab 2: Province Detail Panel
                        Consumer<ProvinceProvider>(
                          builder: (context, provider, child) {
                            return ProvinceDetailPanel(
                              province:
                                  provider.selectedCommune ??
                                  provider.selectedProvince,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
