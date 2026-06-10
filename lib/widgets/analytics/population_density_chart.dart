import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';

class PopulationDensityChart extends StatelessWidget {
  final List<ProvinceModel> provinces;

  const PopulationDensityChart({super.key, required this.provinces});

  @override
  Widget build(BuildContext context) {
    // Lọc các tỉnh có dữ liệu mật độ dân số
    final validProvinces = provinces
        .where((p) => p.density != null && p.density! > 0)
        .toList();

    // Sắp xếp theo mật độ dân số giảm dần (TPHCM sẽ là cao nhất)
    validProvinces.sort((a, b) => (b.density ?? 0).compareTo(a.density ?? 0));

    // Lấy top 15 tỉnh có mật độ cao nhất
    final topProvinces = validProvinces.take(15).toList();

    if (topProvinces.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật Độ Dân Số Theo Tỉnh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: topProvinces.first.density! * 1,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.grey[800]!,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final province = topProvinces[group.x.toInt()];
                    final density = province.density ?? 0;
                    return BarTooltipItem(
                      '${province.name}\n${density.toStringAsFixed(2)} người/km²',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= topProvinces.length) {
                        return const SizedBox();
                      }
                      final provinceName = topProvinces[index].name;
                      return Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          provinceName.length > 12
                              ? '${provinceName.substring(0, 12)}...'
                              : provinceName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 60,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.white12),
                  left: BorderSide(color: Colors.white12),
                  right: BorderSide.none,
                  top: BorderSide.none,
                ),
              ),
              barGroups: List.generate(topProvinces.length, (index) {
                final province = topProvinces[index];
                final density = province.density ?? 0;

                // Đặc biệt tô màu cho TPHCM (mật độ cao nhất)
                final color = index == 0 ? Colors.red : Colors.blue;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: density,
                      color: color,
                      width: 15,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topProvinces.isNotEmpty)
                Text(
                  '🔴 Mật độ cao nhất: ${topProvinces.first.name} (${topProvinces.first.density?.toStringAsFixed(1)} người/km²)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Hiển thị: Top 10 tỉnh có mật độ dân số cao nhất',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
