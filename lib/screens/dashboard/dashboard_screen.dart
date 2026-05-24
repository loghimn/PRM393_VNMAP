import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_detail_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

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

                  const SizedBox(height: 30),

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
      ),
    );
  }
}
