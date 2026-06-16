import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/province_provider.dart';

class PopulationDensityChart extends StatefulWidget {
  final ValueChanged<String>? onMetricChanged;
  const PopulationDensityChart({super.key, this.onMetricChanged});

  @override
  State<PopulationDensityChart> createState() => _PopulationDensityChartState();
}

class _PopulationDensityChartState extends State<PopulationDensityChart> {
  String _selectedMetric = 'density'; // 'density', 'area', 'population'
  int? _customLimit;
  final TextEditingController _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProvinceProvider>().calculateCommuneDensities();
      widget.onMetricChanged?.call(_selectedMetric);
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _onMetricSelected(String metric) {
    setState(() {
      _selectedMetric = metric;
    });
    widget.onMetricChanged?.call(metric);
  }

  Widget _buildMetricChip(String metric, String label) {
    final isSelected = _selectedMetric == metric;
    return GestureDetector(
      onTap: () => _onMetricSelected(metric),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xff1e293b),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white12,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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

  String _formatMetricValue(double value, String metric) {
    if (metric == 'density') {
      return '${_formatNumber(value, isDecimal: true)} người/km²';
    } else if (metric == 'area') {
      return '${_formatNumber(value, isDecimal: true)} km²';
    } else {
      return '${_formatNumber(value.toInt(), isDecimal: false)} người';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProvinceProvider>();
    final densities = provider.calculatedDensities;

    if (provider.isCalculatingDensity || densities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang đọc và phân tích dữ liệu 34 tỉnh/thành phố...',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính toán tổng dân số và diện tích từ cấp xã',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 1. Sort copy of densities based on _selectedMetric descending
    final sortedList = List<Map<String, dynamic>>.from(densities);
    if (_selectedMetric == 'density') {
      sortedList.sort((a, b) => (b['density'] as double).compareTo(a['density'] as double));
    } else if (_selectedMetric == 'area') {
      sortedList.sort((a, b) => (b['area'] as double).compareTo(a['area'] as double));
    } else if (_selectedMetric == 'population') {
      sortedList.sort((a, b) => (b['population'] as double).compareTo(a['population'] as double));
    }

    // 2. Apply custom limit
    final List<Map<String, dynamic>> filteredList;
    if (_customLimit != null && _customLimit! > 0) {
      filteredList = sortedList.take(_customLimit!).toList();
    } else {
      filteredList = sortedList;
    }

    final highestProvince = sortedList.first;
    final lowestProvince = sortedList.last;

    double maxVal;
    double minVal;
    String titleText;
    String subtitleText;
    String highestLabel;
    String lowestLabel;
    String highestValStr;
    String lowestValStr;
    String insightText;

    if (_selectedMetric == 'density') {
      titleText = 'Mật Độ Dân Số Theo Tỉnh';
      subtitleText = 'So sánh mật độ dân số của 34 tỉnh/thành phố...';
      highestLabel = 'Mật độ cao nhất: ';
      lowestLabel = 'Mật độ thấp nhất: ';

      maxVal = highestProvince['density'] as double;
      minVal = lowestProvince['density'] as double;

      highestValStr = _formatMetricValue(maxVal, 'density');
      lowestValStr = _formatMetricValue(minVal, 'density');

      final ratio = minVal > 0 ? (maxVal / minVal).toStringAsFixed(0) : '0';
      insightText = '${highestProvince['name']} có mật độ dân số gấp $ratio lần ${lowestProvince['name']}, thể hiện sự phân bổ dân cư chênh lệch cực lớn giữa các đô thị lớn và vùng miền núi.';
    } else if (_selectedMetric == 'area') {
      titleText = 'Diện Tích Theo Tỉnh';
      subtitleText = 'So sánh diện tích địa lý của 34 tỉnh/thành phố...';
      highestLabel = 'Diện tích lớn nhất: ';
      lowestLabel = 'Diện tích nhỏ nhất: ';

      maxVal = highestProvince['area'] as double;
      minVal = lowestProvince['area'] as double;

      highestValStr = _formatMetricValue(maxVal, 'area');
      lowestValStr = _formatMetricValue(minVal, 'area');

      final ratio = minVal > 0 ? (maxVal / minVal).toStringAsFixed(1) : '0';
      insightText = '${highestProvince['name']} có diện tích gấp $ratio lần ${lowestProvince['name']}, địa hình lãnh thổ Việt Nam phân chia diện tích tự nhiên rất đa dạng.';
    } else {
      titleText = 'Dân Số Theo Tỉnh';
      subtitleText = 'So sánh dân số của 34 tỉnh/thành phố...';
      highestLabel = 'Dân số đông nhất: ';
      lowestLabel = 'Dân số ít nhất: ';

      maxVal = highestProvince['population'] as double;
      minVal = lowestProvince['population'] as double;

      highestValStr = _formatMetricValue(maxVal, 'population');
      lowestValStr = _formatMetricValue(minVal, 'population');

      final ratio = minVal > 0 ? (maxVal / minVal).toStringAsFixed(0) : '0';
      insightText = '${highestProvince['name']} có dân số gấp $ratio lần ${lowestProvince['name']}, phản ánh mật độ định cư tập trung dày đặc ở các trung tâm hành chính và kinh tế trọng điểm.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Metric toggle chips + limit TextField Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Row of Metric Chips
            Row(
              children: [
                _buildMetricChip('density', 'Mật độ'),
                const SizedBox(width: 8),
                _buildMetricChip('area', 'Diện tích'),
                const SizedBox(width: 8),
                _buildMetricChip('population', 'Dân số'),
              ],
            ),
            const SizedBox(width: 16),
            // Custom Limit TextField
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập số lượng top...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    filled: true,
                    fillColor: const Color(0xff1e293b),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    suffixIcon: _limitController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _limitController.clear();
                              setState(() {
                                _customLimit = null;
                              });
                            },
                            child: const Icon(Icons.clear, size: 14, color: Colors.white54),
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val.isEmpty) {
                        _customLimit = null;
                      } else {
                        _customLimit = int.tryParse(val);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Horizontal Scrollable Bar Chart Area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              child: ListView.builder(
                itemCount: filteredList.length,
                padding: const EdgeInsets.only(right: 16),
                itemBuilder: (context, index) {
                  final data = filteredList[index];
                  final name = data['name'] as String;
                  
                  double metricValue;
                  String displayValue;
                  if (_selectedMetric == 'density') {
                    metricValue = data['density'] as double;
                    displayValue = _formatMetricValue(metricValue, 'density');
                  } else if (_selectedMetric == 'area') {
                    metricValue = data['area'] as double;
                    displayValue = _formatMetricValue(metricValue, 'area');
                  } else {
                    metricValue = data['population'] as double;
                    displayValue = _formatMetricValue(metricValue, 'population');
                  }

                  final originalIndex = sortedList.indexWhere((element) => element['key'] == data['key']);
                  final widthFactor = maxVal > 0 ? metricValue / maxVal : 0.0;

                  // Define colors based on rank
                  final isTop3 = originalIndex < 3;
                  final List<Color> barGradientColors = isTop3
                      ? [Colors.redAccent.withOpacity(0.8), Colors.orangeAccent]
                      : [Colors.blueAccent.withOpacity(0.7), Colors.cyanAccent];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Rank Badge based on index
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#${originalIndex + 1}',
                            style: TextStyle(
                              color: isTop3 ? Colors.orangeAccent : Colors.white38,
                              fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        // Province Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Horizontal Bar
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  // Background Track
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  // Animated Bar
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey('${data['key']}_$_selectedMetric'),
                                    tween: Tween<double>(begin: 0, end: widthFactor),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, animValue, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: max(animValue, 0.015),
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: barGradientColors,
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: isTop3
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.orangeAccent.withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    )
                                                  ]
                                                : [],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Value Label
                        Expanded(
                          flex: 2,
                          child: Text(
                            displayValue,
                            style: TextStyle(
                              color: isTop3 ? Colors.redAccent[100] : Colors.blue[100],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Statistics Notes Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff1e293b).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔴', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        children: [
                          TextSpan(text: highestLabel),
                          TextSpan(
                            text: '${highestProvince['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                          TextSpan(
                            text: ' ($highestValStr)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('🟢', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        children: [
                          TextSpan(text: lowestLabel),
                          TextSpan(
                            text: '${lowestProvince['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                          TextSpan(
                            text: ' ($lowestValStr)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              Text(
                '💡 $insightText',
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
