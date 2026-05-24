import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/weather/weather_info_panel.dart';

class ProvinceDetailPanel extends StatelessWidget {
  final ProvinceModel? province;

  const ProvinceDetailPanel({super.key, required this.province});

  @override
  Widget build(BuildContext context) {
    if (province == null) {
      return Container(
        color: const Color(0xff111827),
        padding: const EdgeInsets.all(20),
        child: Consumer<WeatherProvider>(
          builder: (context, weatherProv, child) {
            final summary = weatherProv.nationalWeatherSummary;
            final regions = weatherProv.regionalSummaries.values.toList()
              ..sort((a, b) => a.label.compareTo(b.label));

            if (summary == null && weatherProv.nationalTextSummary.isEmpty) {
              return const Center(
                child: Text(
                  "Đang tải tổng quan thời tiết quốc gia...",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vietnam Weather Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (summary != null) WeatherInfoPanel(weather: summary),
                  if (summary != null) const SizedBox(height: 20),
                  if (regions.isNotEmpty) ...[
                    const Text(
                      'Regional Weather Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: regions.map((region) {
                        return Container(
                          width: 220,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xff1f2937),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                region.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                region.status,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nhiệt độ: ${region.temperatureLabel}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              if (region.weather?.humidity != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Độ ẩm: ${region.weather!.humidity!.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (regions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'Không tìm thấy dữ liệu thời tiết vùng. Vui lòng thử lại sau.',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    final isSpecialZone = province!.type == 'Đặc khu';
    final isCommune = province!.type == 'Phường' || province!.type == 'Xã';

    return Container(
      color: const Color(0xff111827),
      padding: const EdgeInsets.all(20),

      child: (isSpecialZone || isCommune)
          ? _buildSpecialZoneDetail()
          : _buildProvinceDetail(),
    );
  }

  Widget _buildProvinceDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            province!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Consumer<WeatherProvider>(
            builder: (context, weatherProv, child) {
              final w = weatherProv.getCachedWeatherForProvince(province!);
              return WeatherInfoPanel(weather: w);
            },
          ),

          const SizedBox(height: 12),

          _buildInfo("Code", province!.ma),

          _buildInfo("Area", "${province!.areaKm2} km²"),

          _buildInfo("Population", province!.population),

          _buildInfo("Density", province!.density),

          _buildInfo("Capital", province!.capital),

          _buildInfo("Region", province!.macroRegion),

          const SizedBox(height: 24),

          const Divider(color: Colors.white24),

          const SizedBox(height: 24),

          Text(
            "Decree",
            style: TextStyle(
              color: Colors.orange.shade300,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.decree ?? "-",
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialZoneDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            province!.name,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Consumer<WeatherProvider>(
            builder: (context, weatherProv, child) {
              final w = weatherProv.getCachedWeatherForProvince(province!);
              return WeatherInfoPanel(weather: w);
            },
          ),

          const SizedBox(height: 12),

          _buildInfo("Type", province!.type),

          _buildInfo("Code", province!.ma),

          _buildInfo("Area", "${province!.areaKm2} km²"),

          _buildInfo("Population", province!.population),

          _buildInfo("Density", province!.density),

          _buildInfo("Capital", province!.capital),

          _buildInfo("Macro Region", province!.macroRegion),

          _buildInfo("Parent Code", province!.parentMa),

          _buildInfo("Parent", province!.parentTen),

          const SizedBox(height: 20),

          Text(
            "Predecessors",
            style: TextStyle(
              color: Colors.cyan.shade200,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.predecessors ?? "-",
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),

          const SizedBox(height: 24),

          Text(
            "Decree",
            style: TextStyle(
              color: Colors.orange.shade300,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.decree ?? "-",
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              "$value",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
