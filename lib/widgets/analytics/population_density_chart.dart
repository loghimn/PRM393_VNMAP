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
  double _displayLimit = 34; // slider value: 1-34

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
    super.dispose();
  }

  int get _displayCount => _displayLimit.round();

  void _onMetricSelected(String metric) {
    setState(() {
      _selectedMetric = metric;
    });
    widget.onMetricChanged?.call(metric);
  }

  // ── Filter Chips: height 44, radius 22, padding 20 ──
  Widget _buildMetricChip(String metric, String label) {
    final isSelected = _selectedMetric == metric;
    return GestureDetector(
      onTap: () => _onMetricSelected(metric),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 44,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
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
            Text(
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

    // Chỉ lấy top N theo slider
    final displayList = sortedList.take(_displayCount).toList();
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

    // Layout: Column with all content
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Title (Fixed) ──
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
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
            const SizedBox(height: 8),

            // ── Section Subtitle (Fixed) ──
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'So sánh số liệu giữa các tỉnh/thành phố',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),

            // ── Filter Chips (Fixed) ──
            LayoutBuilder(
              builder: (context, constraints) {
                final chipWidth = (constraints.maxWidth - 16) / 3;
                final needsWrap = chipWidth < 80;
                if (needsWrap) {
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildMetricChip('density', 'Mật độ'),
                      _buildMetricChip('area', 'Diện tích'),
                      _buildMetricChip('population', 'Dân số'),
                    ],
                  );
                }
                return Row(
                  children: [
                    _buildMetricChip('density', 'Mật độ'),
                    const SizedBox(width: 8),
                    _buildMetricChip('area', 'Diện tích'),
                    const SizedBox(width: 8),
                    _buildMetricChip('population', 'Dân số'),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // ── Slider: chọn số lượng tỉnh hiển thị ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.border.withValues(
                          alpha: 0.3,
                        ),
                        thumbColor: AppColors.primary,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20,
                        ),
                        valueIndicatorColor: AppColors.primary,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Slider(
                        min: 1,
                        max: 34,
                        divisions: 33,
                        value: _displayLimit,
                        label: '$_displayCount tỉnh',
                        onChanged: (val) => setState(() => _displayLimit = val),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$_displayCount tỉnh',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Ranking Card (Non-scrollable) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground,
                borderRadius: BorderRadius.circular(AppColors.cardRadius),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.4),
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: displayList.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final data = displayList[index];
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

                  final widthFactor = maxVal > 0 ? metricValue / maxVal : 0.0;

                  // Color based on rank
                  final isTop3 = index < 3;
                  final isBottom3 = index >= displayList.length - 3;
                  final Color barColor = isTop3
                      ? AppColors.primary
                      : isBottom3
                      ? AppColors.error.withValues(alpha: 0.6)
                      : AppColors.primaryLight.withValues(alpha: 0.6);

                  return Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: index == displayList.length - 1 ? 0 : 12,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 360;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Rank + Name + Value
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Rank Number (#1, #2, ...)
                                SizedBox(
                                  width: isCompact ? 22 : 28,
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      color: isTop3
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: isTop3
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: isCompact ? 12 : 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Province Name (Expanded)
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: isCompact ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Value label - right aligned
                                Text(
                                  displayValue,
                                  style: TextStyle(
                                    color: isTop3
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: isCompact ? 11 : 13,
                                    fontWeight: isTop3
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Progress bar - full width
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 6,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    // Background
                                    Container(
                                      color: AppColors.border.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    // Progress bar
                                    FractionallySizedBox(
                                      widthFactor: min(widthFactor, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: isTop3
                                              ? AppColors.primaryGradient
                                              : null,
                                          color: isTop3 ? null : barColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Summary Cards (Fixed) ──
            Row(
              children: [
                // Highest Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(AppColors.cardRadius),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.4),
                      ),
                      boxShadow: AppColors.cardShadow,
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
                                style: TextStyle(
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
                      borderRadius: BorderRadius.circular(AppColors.cardRadius),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.4),
                      ),
                      boxShadow: AppColors.cardShadow,
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
                                style: TextStyle(
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
                color: AppColors.highlightBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insightText,
                      style: TextStyle(
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
        ),
      ),
    );
  }
}
