import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';
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
                    'Tổng quan thời tiết Việt Nam',
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
                      'Tổng quan thời tiết vùng',
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

      child: isCommune
          ? _buildCommuneDetail()
          : (isSpecialZone
                ? _buildSpecialZoneDetail()
                : _buildProvinceDetail()),
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

          Consumer<WeatherProvider>(
            builder: (context, weatherProv, child) {
              final w = weatherProv.getCachedWeatherForProvince(province!);
              return WeatherInfoPanel(weather: w);
            },
          ),

          const SizedBox(height: 12),

          _buildInfo("Mã hành chính", province!.ma),

          _buildInfo("Diện tích", "${province!.areaKm2} km²"),

          _buildInfo("Dân số", province!.population),

          _buildInfo("Mật độ dân số", province!.density),

          _buildInfo("Tỉnh lỵ", province!.capital),

          _buildInfo("Vùng địa lý", province!.macroRegionVietnamese),

          const SizedBox(height: 24),

          const Divider(color: Colors.white24),

          const SizedBox(height: 24),

          Text(
            "Nghị định / Quyết định",
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

          _buildInfo("Phân loại", province!.type),

          _buildInfo("Mã hành chính", province!.ma),

          _buildInfo("Diện tích", "${province!.areaKm2} km²"),

          _buildInfo("Dân số", province!.population),

          _buildInfo("Mật độ dân số", province!.density),

          _buildInfo("Trung tâm hành chính", province!.capital),

          _buildInfo("Vùng địa lý", province!.macroRegionVietnamese),

          _buildInfo("Mã cấp trên", province!.parentMa),

          _buildInfo("Đơn vị cấp trên", province!.parentTen),

          const SizedBox(height: 20),

          Text(
            "Đơn vị tiền thân",
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
            "Nghị định / Quyết định",
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

  Widget _buildCommuneDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commune name header
          Text(
            province!.name,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Commune basic info
          _buildInfo("Phân loại", province!.type),
          _buildInfo("Mã hành chính", province!.ma),
          _buildInfo("Diện tích", "${province!.areaKm2} km²"),
          _buildInfo("Dân số", province!.population),
          _buildInfo("Mật độ dân số", province!.density),
          _buildInfo("Thuộc tỉnh", province!.parentTen ?? ""),

          const SizedBox(height: 24),

          // Weather widget
          Consumer<WeatherProvider>(
            builder: (context, weatherProv, child) {
              final w = weatherProv.getCachedWeatherForProvince(province!);
              return WeatherInfoPanel(weather: w);
            },
          ),

          const SizedBox(height: 24),

          const Divider(color: Colors.white24),

          const SizedBox(height: 16),

          // High Schools section
          _buildHighSchoolsSection(),
        ],
      ),
    );
  }

  Widget _buildHighSchoolsSection() {
    return Consumer<ProvinceProvider>(
      builder: (context, prov, child) {
        final schools = prov.selectedCommuneHighSchools;
        final isLoading = prov.isLoadingHighSchools;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.orange.shade300, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Trường THPT trên địa bàn",
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isLoading && schools.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Không có dữ liệu trường THPT cho xã/phường này.",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            if (!isLoading && schools.isNotEmpty)
              ...schools.map((school) => _buildHighSchoolCard(school)),
          ],
        );
      },
    );
  }

  Widget _buildHighSchoolCard(HighSchool school) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1f2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            school.tenTruong ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (school.diaChi != null && school.diaChi!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    school.diaChi!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          if (school.khuVuc != null && school.khuVuc!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  school.khuVuc!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
          if (school.maTruong != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.tag, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Mã trường: ${school.maTruong!}",
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],
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
