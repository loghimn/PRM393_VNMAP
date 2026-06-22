import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';
import 'package:vietnam_geo_dashboard/widgets/weather/weather_info_panel.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

class ProvinceDetailPanel extends StatelessWidget {
  final ProvinceModel? province;

  const ProvinceDetailPanel({super.key, required this.province});

  @override
  Widget build(BuildContext context) {
    if (province == null) {
      return Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(20),
        child: Consumer<WeatherProvider>(
          builder: (context, weatherProv, child) {
            final summary = weatherProv.nationalWeatherSummary;
            final regions = weatherProv.regionalSummaries.values.toList()
              ..sort((a, b) => a.label.compareTo(b.label));

            if (summary == null && weatherProv.nationalTextSummary.isEmpty) {
              return Center(
                child: Text(
                  "Đang tải tổng quan thời tiết quốc gia...",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan thời tiết Việt Nam',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  if (summary != null) WeatherInfoPanel(weather: summary),
                  if (summary != null) const SizedBox(height: 20),
                  if (regions.isNotEmpty) ...[
                    Text(
                      'Tổng quan thời tiết vùng',
                      style: Theme.of(context).textTheme.titleLarge,
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppColors.cardRadius,
                            ),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                region.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                region.status,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nhiệt độ: ${region.temperatureLabel}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (region.weather?.humidity != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Độ ẩm: ${region.weather!.humidity!.toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (regions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Không tìm thấy dữ liệu thời tiết vùng. Vui lòng thử lại sau.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
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
      color: AppColors.background,
      padding: const EdgeInsets.all(20),

      child: isCommune
          ? _buildCommuneDetail(context)
          : (isSpecialZone
                ? _buildSpecialZoneDetail(context)
                : _buildProvinceDetail(context)),
    );
  }

  Widget _buildProvinceDetail(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            province!.name,
            style: Theme.of(context).textTheme.headlineLarge,
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

          Divider(color: AppColors.divider),

          const SizedBox(height: 24),

          Text(
            "Nghị định / Quyết định",
            style: TextStyle(
              color: AppColors.accentLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.decree ?? "-",
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialZoneDetail(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            province!.name,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: AppColors.secondary),
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
              color: AppColors.secondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.predecessors ?? "-",
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),

          const SizedBox(height: 24),

          Text(
            "Nghị định / Quyết định",
            style: TextStyle(
              color: AppColors.accentLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.decree ?? "-",
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCommuneDetail(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commune name header
          Text(
            province!.name,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: AppColors.accent),
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

          Divider(color: AppColors.divider),

          const SizedBox(height: 16),

          // High Schools section
          _buildHighSchoolsSection(context),
        ],
      ),
    );
  }

  Widget _buildHighSchoolsSection(BuildContext context) {
    return Consumer<ProvinceProvider>(
      builder: (context, prov, child) {
        final schools = prov.selectedCommuneHighSchools;
        final isLoading = prov.isLoadingHighSchools;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppColors.accentLight, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Trường THPT trên địa bàn",
                  style: TextStyle(
                    color: AppColors.accentLight,
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Không có dữ liệu trường THPT cho xã/phường này.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            school.tenTruong ?? "",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (school.diaChi != null && school.diaChi!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    school.diaChi!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (school.khuVuc != null && school.khuVuc!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  school.khuVuc!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          if (school.maTruong != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.tag, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Mã trường: ${school.maTruong!}",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              "$value",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
