import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/province_model.dart';
import '../../providers/province_provider.dart';

class OverviewStatisticsTab extends StatefulWidget {
  const OverviewStatisticsTab({super.key});

  @override
  State<OverviewStatisticsTab> createState() => _OverviewStatisticsTabState();
}

class _OverviewStatisticsTabState extends State<OverviewStatisticsTab> {
  // Current active metric for ranking view: 'population', 'area', 'density'
  String _activeRankingMetric = 'population';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProvinceProvider>();
    final provinces = provider.provinces;

    if (provinces.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
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

    // Sort regions by population descending
    regionStats.sort((a, b) => (b['population'] as double).compareTo(a['population'] as double));
    final double maxRegionPop = regionStats.isNotEmpty ? regionStats.first['population'] as double : 1.0;

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
          // National KPI Summary Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildKPICard(
                title: 'Tổng dân số',
                value: _formatNumber(totalPopulation),
                unit: 'người',
                icon: Icons.people_alt,
                gradient: const [Color(0xff2563eb), Color(0xff06b6d4)],
              ),
              _buildKPICard(
                title: 'Tổng diện tích',
                value: _formatNumber(totalArea, isDecimal: true),
                unit: 'km²',
                icon: Icons.landscape,
                gradient: const [Color(0xff059669), Color(0xff10b981)],
              ),
              _buildKPICard(
                title: 'Mật độ trung bình',
                value: _formatNumber(avgDensity, isDecimal: true),
                unit: 'người/km²',
                icon: Icons.density_medium,
                gradient: const [Color(0xff7c3aed), Color(0xffa855f7)],
              ),
              _buildKPICard(
                title: 'Đơn vị hành chính',
                value: '${provinces.length}',
                unit: 'Tỉnh/Thành',
                icon: Icons.location_city,
                subtext: '$cityCount TP • $provinceCount Tỉnh',
                gradient: const [Color(0xffdb2777), Color(0xfff43f5e)],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Region Statistics
          const Text(
            'Phân Tích Theo Vùng Địa Lý',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1e293b).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: regionStats.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 20),
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count địa phương',
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Visual Population share bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 8,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * pct,
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.withOpacity(0.8), Colors.cyanAccent],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Stat numbers row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSubStat('Dân số', '${_formatNumber(rPop)} người'),
                        _buildSubStat('Diện tích', '${_formatNumber(rArea, isDecimal: true)} km²'),
                        _buildSubStat('Mật độ', '${_formatNumber(rDensity, isDecimal: true)} /km²'),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Rankings Header & Tab Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xếp Hạng Địa Phương',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Segmented selector
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(8),
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

          // Rankings Side-by-Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top 3 Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Cao Nhất',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: Colors.greenAccent.withOpacity(0.2),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 24.0),
                                child: Text(
                                  '${_formatNumber(val, isDecimal: isDecimal)} $activeUnit',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_down, color: Colors.redAccent, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Thấp Nhất',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 24.0),
                                child: Text(
                                  '${_formatNumber(val, isDecimal: isDecimal)} $activeUnit',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required List<Color> gradient,
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 12),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
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
