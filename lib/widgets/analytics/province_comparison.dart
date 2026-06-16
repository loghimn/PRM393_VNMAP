import 'package:flutter/material.dart';
import '../../models/province_model.dart';

class ProvinceComparison extends StatefulWidget {
  final List<ProvinceModel> provinces;

  const ProvinceComparison({super.key, required this.provinces});

  @override
  State<ProvinceComparison> createState() => _ProvinceComparisonState();
}

class _ProvinceComparisonState extends State<ProvinceComparison> {
  ProvinceModel? selectedProvince1;
  ProvinceModel? selectedProvince2;

  @override
  void initState() {
    super.initState();
    if (widget.provinces.isNotEmpty) {
      selectedProvince1 = widget.provinces[0];
      if (widget.provinces.length > 1) {
        selectedProvince2 = widget.provinces[1];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So Sánh Hai Tỉnh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Province Selection Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tỉnh 1',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<ProvinceModel>(
                      value: selectedProvince1,
                      dropdownColor: const Color(0xff0f172a),
                      isExpanded: true,
                      items: widget.provinces
                          .where((p) => p.name != selectedProvince2?.name)
                          .map((province) {
                        return DropdownMenuItem(
                          value: province,
                          child: Text(
                            province.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProvince1 = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tỉnh 2',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<ProvinceModel>(
                      value: selectedProvince2,
                      dropdownColor: const Color(0xff0f172a),
                      isExpanded: true,
                      items: widget.provinces
                          .where((p) => p.name != selectedProvince1?.name)
                          .map((province) {
                        return DropdownMenuItem(
                          value: province,
                          child: Text(
                            province.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProvince2 = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Comparison Dashboard
          if (selectedProvince1 != null && selectedProvince2 != null) ...[
            _buildMetricChart(
              title: 'Dân Số',
              icon: Icons.people_alt,
              val1: (selectedProvince1!.population ?? 0).toDouble(),
              val2: (selectedProvince2!.population ?? 0).toDouble(),
              unit: 'người',
              p1Name: selectedProvince1!.name,
              p2Name: selectedProvince2!.name,
            ),
            _buildMetricChart(
              title: 'Diện Tích',
              icon: Icons.landscape,
              val1: selectedProvince1!.areaKm2 ?? 0.0,
              val2: selectedProvince2!.areaKm2 ?? 0.0,
              unit: 'km²',
              p1Name: selectedProvince1!.name,
              p2Name: selectedProvince2!.name,
              isDecimal: true,
            ),
            _buildMetricChart(
              title: 'Mật Độ Dân Số',
              icon: Icons.density_medium,
              val1: selectedProvince1!.density ?? 0.0,
              val2: selectedProvince2!.density ?? 0.0,
              unit: 'người/km²',
              p1Name: selectedProvince1!.name,
              p2Name: selectedProvince2!.name,
              isDecimal: true,
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(num? value, {bool isDecimal = false}) {
    if (value == null) return 'Không có dữ liệu';
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

  Widget _buildMetricChart({
    required String title,
    required IconData icon,
    required double val1,
    required double val2,
    required String unit,
    required String p1Name,
    required String p2Name,
    bool isDecimal = false,
  }) {
    final maxVal = val1 > val2 ? val1 : val2;
    final pct1 = maxVal > 0 ? val1 / maxVal : 0.0;
    final pct2 = maxVal > 0 ? val2 / maxVal : 0.0;

    final isP1Winner = val1 > val2;
    final isP2Winner = val2 > val1;

    // Calculate ratio comparison
    String ratioText = '';
    if (val1 > 0 && val2 > 0) {
      if (val1 > val2) {
        final ratio = val1 / val2;
        ratioText = '$p1Name cao hơn ${ratio.toStringAsFixed(1)} lần';
      } else if (val2 > val1) {
        final ratio = val2 / val1;
        ratioText = '$p2Name cao hơn ${ratio.toStringAsFixed(1)} lần';
      } else {
        ratioText = 'Hai tỉnh bằng nhau';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (ratioText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Text(
                    ratioText,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Province 1 Progress Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p1Name,
                            style: TextStyle(
                              color: isP1Winner ? Colors.white : Colors.white70,
                              fontWeight: isP1Winner ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isP1Winner) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, color: Colors.blueAccent, size: 12),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${_formatNumber(val1, isDecimal: isDecimal)} $unit',
                    style: TextStyle(
                      color: isP1Winner ? Colors.blueAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress Bar P1
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 10,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: constraints.maxWidth * pct1,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.cyanAccent],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Province 2 Progress Row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p2Name,
                            style: TextStyle(
                              color: isP2Winner ? Colors.white : Colors.white70,
                              fontWeight: isP2Winner ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isP2Winner) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, color: Colors.orangeAccent, size: 12),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${_formatNumber(val2, isDecimal: isDecimal)} $unit',
                    style: TextStyle(
                      color: isP2Winner ? Colors.orangeAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress Bar P2
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 10,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: constraints.maxWidth * pct2,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.pinkAccent],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
