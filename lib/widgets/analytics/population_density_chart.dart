import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.border.withOpacity(0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang đọc và phân tích dữ liệu 34 tỉnh/thành phố...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính toán tổng dân số và diện tích từ cấp xã',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Sort
    final sortedList = List<Map<String, dynamic>>.from(densities);
    if (_selectedMetric == 'density') {
      sortedList.sort(
        (a, b) => (b['density'] as double).compareTo(a['density'] as double),
      );
    } else if (_selectedMetric == 'area') {
      sortedList.sort(
        (a, b) => (b['area'] as double).compareTo(a['area'] as double),
      );
    } else if (_selectedMetric == 'population') {
      sortedList.sort(
        (a, b) =>
            (b['population'] as double).compareTo(a['population'] as double),
      );
    }

    // Apply custom limit
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
      highestLabel = 'Cao nhất';
      lowestLabel = 'Thấp nhất';

      maxVal = highestProvince['density'] as double;
      minVal = lowestProvince['density'] as double;

      highestValStr = _formatMetricValue(maxVal, 'density');
      lowestValStr = _formatMetricValue(minVal, 'density');

      final ratio = minVal > 0 ? (maxVal / minVal).toStringAsFixed(0) : '0';
      insightText =
          '${highestProvince['name']} có mật độ dân số gấp $ratio lần ${lowestProvince['name']}, thể hiện sự phân bổ dân cư chênh lệch cực lớn giữa các đô thị lớn và vùng miền núi.';
    } else if (_selectedMetric == 'area') {
      titleText = 'Diện Tích Theo Tỉnh';
      subtitleText = 'So sánh diện tích địa lý của 34 tỉnh/thành phố...';
      highestLabel = 'Lớn nhất';
      lowestLabel = 'Nhỏ nhất';

      maxVal = highestProvince['area'] as double;
      minVal = lowestProvince['area'] as double;

      highestValStr = _formatMetricValue(maxVal, 'area');
      lowestValStr = _formatMetricValue(minVal, 'area');

      final ratio = minVal > 0 ? (maxVal / minVal).toStringAsFixed(1) : '0';
      insightText =
          '${highestProvince['name']} có diện tích gấp $ratio lần ${lowestProvince['name']}, địa hình lãnh thổ Việt Nam phân chia diện tích tự nhiên rất đa dạng.';
    } else {
      titleText = 'Dân Số Theo Tỉnh';
      subtitleText = 'So sánh dân số của 34 tỉnh/thành phố...';
      highestLabel = 'Đông nhất';
      lowestLabel = 'Ít nhất';

      maxVal = highestProvince['population'] as double;
      minVal = lowestProvince['population'] as double;

      highestValStr = _formatMetricValue(maxVal, 'population');
      lowestValStr = _formatMetricValue(minVal, 'population');

      final ratio = minVal > 0 ? (maxVal / minVal).toStringAsFixed(0) : '0';
      insightText =
          '${highestProvince['name']} có dân số gấp $ratio lần ${lowestProvince['name']}, phản ánh mật độ định cư tập trung dày đặc ở các trung tâm hành chính và kinh tế trọng điểm.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title Row ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Metric Chips + Limit Field ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập số lượng top...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.5),
                      fontSize: 11,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    suffixIcon: _limitController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _limitController.clear();
                              setState(() {
                                _customLimit = null;
                              });
                            },
                            child: const Icon(
                              Icons.clear,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
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

        // ── Bar Chart (White Card) ──
        Expanded(
          child: Container(
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
                    displayValue = _formatMetricValue(
                      metricValue,
                      'population',
                    );
                  }

                  final originalIndex = sortedList.indexWhere(
                    (element) => element['key'] == data['key'],
                  );
                  final widthFactor = maxVal > 0 ? metricValue / maxVal : 0.0;

                  // Color based on rank
                  final isTop3 = originalIndex < 3;
                  final List<Color> barGradientColors = isTop3
                      ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                      : [const Color(0xFF93C5FD), const Color(0xFF60A5FA)];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // Rank Badge
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#${originalIndex + 1}',
                            style: TextStyle(
                              color: isTop3
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight: isTop3
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Horizontal Bar (Thicker - 14px height)
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  // Background Track
                                  Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.border.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  // Animated Bar
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey(
                                      '${data['key']}_$_selectedMetric',
                                    ),
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: widthFactor,
                                    ),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, animValue, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: max(animValue, 0.015),
                                        child: Container(
                                          height: 14,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: barGradientColors,
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            boxShadow: isTop3
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primary
                                                          .withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        1,
                                                      ),
                                                    ),
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
                              color: isTop3
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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

        // ── Summary Cards (Compact) ──
        Row(
          children: [
            // Highest Card
            Expanded(
              child: Container(
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↑ $highestLabel',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${highestProvince['name']}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            highestValStr,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Lowest Card
            Expanded(
              child: Container(
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↓ $lowestLabel',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lowestProvince['name']}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lowestValStr,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 12),
        // Insight Text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.highlightBg.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insightText,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
