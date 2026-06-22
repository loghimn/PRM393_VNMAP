import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/province_model.dart';
import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

class OverviewStatisticsTab extends StatefulWidget {
  const OverviewStatisticsTab({super.key});

  @override
  State<OverviewStatisticsTab> createState() => _OverviewStatisticsTabState();
}

class _OverviewStatisticsTabState extends State<OverviewStatisticsTab> {
  String _activeRankingMetric = 'population';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProvinceProvider>();
    final provinces = provider.provinces;

    if (provinces.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Calculations
    double totalPopulation = 0;
    double totalArea = 0;
    int cityCount = 0;
    int provinceCount = 0;

    for (final p in provinces) {
      totalPopulation += (p.population ?? 0);
      totalArea += (p.areaKm2 ?? 0);
      final type = p.type?.toLowerCase() ?? '';
      if (type.contains('thành phố') || type.contains('city')) {
        cityCount++;
      } else {
        provinceCount++;
      }
    }

    final double avgDensity = totalArea > 0 ? totalPopulation / totalArea : 0;

    // Grouping by Region
    final Map<String, List<ProvinceModel>> regionGroups = {};
    for (final p in provinces) {
      final region = p.macroRegionVietnamese;
      regionGroups.putIfAbsent(region, () => []).add(p);
    }

    final List<Map<String, dynamic>> regionStats = [];
    regionGroups.forEach((regionName, list) {
      double rPop = 0;
      double rArea = 0;
      for (final p in list) {
        rPop += (p.population ?? 0);
        rArea += (p.areaKm2 ?? 0);
      }
      final double rDensity = rArea > 0 ? rPop / rArea : 0;
      regionStats.add({
        'name': regionName,
        'population': rPop,
        'area': rArea,
        'density': rDensity,
        'count': list.length,
      });
    });

    regionStats.sort(
      (a, b) =>
          (b['population'] as double).compareTo(a['population'] as double),
    );
    final double maxRegionPop = regionStats.isNotEmpty
        ? regionStats.first['population'] as double
        : 1.0;

    // Sorting for rankings
    final List<ProvinceModel> sortedByPop = List.from(provinces)
      ..sort((a, b) => (b.population ?? 0).compareTo(a.population ?? 0));

    final List<ProvinceModel> sortedByArea = List.from(provinces)
      ..sort((a, b) => (b.areaKm2 ?? 0).compareTo(a.areaKm2 ?? 0));

    final List<ProvinceModel> sortedByDensity = List.from(provinces)
      ..sort((a, b) => (b.density ?? 0).compareTo(a.density ?? 0));

    List<ProvinceModel> activeSorted;
    String activeUnit = '';
    bool isDecimal = false;

    if (_activeRankingMetric == 'population') {
      activeSorted = sortedByPop;
      activeUnit = 'người';
    } else if (_activeRankingMetric == 'area') {
      activeSorted = sortedByArea;
      activeUnit = 'km²';
      isDecimal = true;
    } else {
      activeSorted = sortedByDensity;
      activeUnit = 'người/km²';
      isDecimal = true;
    }

    final top3 = activeSorted.take(3).toList();
    final bottom3 = activeSorted.reversed.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards (Redesigned) ──
          Row(
            children: [
              Expanded(
                child: _buildKPI(
                  value: _formatNumber(totalPopulation),
                  label: 'Tổng dân số',
                  icon: Icons.people_alt,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPI(
                  value: '${_formatNumber(totalArea, isDecimal: true)} km²',
                  label: 'Tổng diện tích',
                  icon: Icons.straighten,
                  gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPI(
                  value: '${_formatNumber(avgDensity, isDecimal: true)}',
                  label: 'Mật độ TB (/km²)',
                  icon: Icons.density_medium,
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPI(
                  value: '${provinces.length}',
                  label: 'Tỉnh/Thành phố',
                  icon: Icons.location_city,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  sublabel: '$cityCount TP • $provinceCount Tỉnh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Region Statistics ──
          Text(
            'Phân Tích Theo Vùng Địa Lý',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: regionStats.length,
              separatorBuilder: (context, index) =>
                  Divider(color: AppColors.divider, height: 24),
              itemBuilder: (context, index) {
                final stat = regionStats[index];
                final String name = stat['name'];
                final double rPop = stat['population'];
                final double rArea = stat['area'];
                final double rDensity = stat['density'];
                final int count = stat['count'];
                final double pct = maxRegionPop > 0 ? rPop / maxRegionPop : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count địa phương',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Population share bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 8,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: AppColors.border.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSubStat('Dân số', '${_formatNumber(rPop)} người'),
                        _buildSubStat(
                          'Diện tích',
                          '${_formatNumber(rArea, isDecimal: true)} km²',
                        ),
                        _buildSubStat(
                          'Mật độ',
                          '${_formatNumber(rDensity, isDecimal: true)} /km²',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── Rankings ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Xếp Hạng Địa Phương',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    _buildMetricButton('population', 'Dân số'),
                    _buildMetricButton('area', 'D.Tích'),
                    _buildMetricButton('density', 'M.Độ'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top 3 Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Cao Nhất',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...top3.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;
                        double val = 0;
                        if (_activeRankingMetric == 'population') {
                          val = (p.population ?? 0).toDouble();
                        } else if (_activeRankingMetric == 'area') {
                          val = p.areaKm2 ?? 0.0;
                        } else {
                          val = p.density ?? 0.0;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: index == 0
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFF59E0B),
                                            Color(0xFFD97706),
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF94A3B8),
                                            Color(0xFF64748B),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${_formatNumber(val, isDecimal: isDecimal)} $activeUnit',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bottom 3 Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.trending_down,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Thấp Nhất',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...bottom3.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;
                        double val = 0;
                        if (_activeRankingMetric == 'population') {
                          val = (p.population ?? 0).toDouble();
                        } else if (_activeRankingMetric == 'area') {
                          val = p.areaKm2 ?? 0.0;
                        } else {
                          val = p.density ?? 0.0;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${_formatNumber(val, isDecimal: isDecimal)} $activeUnit',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricButton(String metric, String label) {
    final isSelected = _activeRankingMetric == metric;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeRankingMetric = metric;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKPI({
    required String value,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    String? sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  overflow: TextOverflow.ellipsis,
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
                if (sublabel != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    sublabel,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatNumber(num? value, {bool isDecimal = false}) {
    if (value == null) return '0';
    if (isDecimal) {
      final parts = value.toStringAsFixed(1).split('.');
      final whole = parts[0];
      final decimal = parts[1];

      final buffer = StringBuffer();
      for (int i = 0; i < whole.length; i++) {
        if (i > 0 && (whole.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(whole[i]);
      }
      return '${buffer.toString()},$decimal';
    } else {
      final str = value.toInt().toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
  }
}
