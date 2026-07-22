import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/statistics_provider.dart';
import '../../utils/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String displayName) {
    switch (displayName) {
      case 'Received':
      case 'Đã nhận':
      case 'Tiếp nhận':
        return AppColors.primary;
      case 'Processing':
      case 'Đang xử lý':
      case 'Xử lý':
        return AppColors.warning;
      case 'Completed':
      case 'Hoàn thành':
      case 'Đã xong':
        return AppColors.success;
      case 'Cancelled':
      case 'Đã hủy':
      case 'Hủy':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thống kê sự cố',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Theo tháng', icon: Icon(Icons.calendar_month, size: 18)),
            Tab(text: 'Theo khu phố', icon: Icon(Icons.location_on, size: 18)),
            Tab(text: 'Theo trạng thái', icon: Icon(Icons.pie_chart, size: 18)),
          ],
        ),
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAll(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTheoThangTab(provider),
              _buildTheoKhuPhoTab(provider),
              _buildTheoTrangThaiTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTheoThangTab(StatisticsProvider provider) {
    final data = provider.incidentsByMonth;
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final double maxVal = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 10;
    final double maxY = maxVal + (maxVal * 0.15).ceilToDouble();
    final double interval = maxY > 10 ? (maxY / 5).ceilToDouble() : 2;

    final statusData = provider.incidentsByStatus;
    final total = statusData.values.fold<int>(0, (sum, v) => sum + v);
    final received = statusData['Received'] ?? 0;
    final processing = statusData['Processing'] ?? 0;
    final completed = statusData['Completed'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI summary row
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildKpiCard(
                title: 'Tổng sự vụ',
                value: '$total',
                icon: Icons.assignment_rounded,
                gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              _buildKpiCard(
                title: 'Đã hoàn thành',
                value: '$completed',
                icon: Icons.check_circle_rounded,
                gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              _buildKpiCard(
                title: 'Đang xử lý',
                value: '$processing',
                icon: Icons.sync_rounded,
                gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              ),
              _buildKpiCard(
                title: 'Đang chờ',
                value: '$received',
                icon: Icons.hourglass_empty_rounded,
                gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main monthly chart card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thống kê theo tháng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.border.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: provider.selectedYear,
                          dropdownColor: AppColors.surfaceSubtleDark,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight, size: 18),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          items: List.generate(
                            5,
                            (i) => DropdownMenuItem(
                              value: DateTime.now().year - i,
                              child: Text('${DateTime.now().year - i}'),
                            ),
                          ),
                          onChanged: (year) {
                            if (year != null) {
                              provider.setSelectedYear(year);
                              provider.loadByMonth();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY <= 0 ? 10 : maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => AppColors.surfaceSubtleDark.withAlpha(240),
                          tooltipBorder: BorderSide(color: AppColors.primary.withAlpha(100), width: 1),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Tháng ${group.x}\n',
                              const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '${rod.toY.toInt()} sự vụ',
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
                              final intVal = value.toInt();
                              if (intVal >= 1 && intVal <= 12) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'T$intVal',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 24,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: interval <= 0 ? 2 : interval,
                            getTitlesWidget: (value, meta) {
                              if (value == value.toInt()) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval <= 0 ? 2 : interval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.border.withAlpha(20),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.entries.map((entry) {
                        final month =
                            int.tryParse(entry.key.replaceAll('Month ', '').replaceAll('Tháng ', '')) ?? 1;
                        return BarChartGroupData(
                          x: month,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY <= 0 ? 10 : maxY,
                                color: AppColors.border.withAlpha(10),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết sự vụ theo tháng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ...data.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.replaceAll('Month ', 'Tháng '),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          '${entry.value} sự cố',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withAlpha(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheoKhuPhoTab(StatisticsProvider provider) {
    final data = provider.incidentsByNeighborhood;
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final maxValue = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 1;

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int rank = 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sự cố theo khu phố',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ...entries.map((entry) {
                  final currentRank = rank++;
                  
                  List<Color> gradientColors;
                  if (currentRank == 1) {
                    gradientColors = const [Color(0xFFF59E0B), Color(0xFFD97706)];
                  } else if (currentRank == 2) {
                    gradientColors = const [Color(0xFF94A3B8), Color(0xFF64748B)];
                  } else if (currentRank == 3) {
                    gradientColors = const [Color(0xFFB45309), Color(0xFF78350F)];
                  } else {
                    gradientColors = const [Color(0xFF3B82F6), Color(0xFF60A5FA)];
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        _buildRankBadge(currentRank),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value} sự vụ',
                                    style: TextStyle(
                                      color: currentRank <= 3 
                                          ? gradientColors[0] 
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final double pct = maxValue > 0 ? entry.value / maxValue : 0;
                                  return Stack(
                                    children: [
                                      Container(
                                        height: 6,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.border.withAlpha(20),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      Container(
                                        height: 6,
                                        width: constraints.maxWidth * pct,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: gradientColors,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${data.values.fold<int>(0, (sum, v) => sum + v)} sự vụ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 16));
    } else if (rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 16));
    } else if (rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 16));
    }

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.border.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTheoTrangThaiTab(StatisticsProvider provider) {
    final data = provider.incidentsByStatus;
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final total = data.values.fold<int>(0, (sum, v) => sum + v);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tỷ lệ trạng thái sự cố',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                if (total > 0)
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 140,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                              sections: data.entries.map((entry) {
                                return PieChartSectionData(
                                  color: _statusColor(entry.key),
                                  value: entry.value.toDouble(),
                                  title: '',
                                  radius: 12,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: data.entries.map((entry) {
                            String statusLabel;
                            switch (entry.key) {
                              case 'Received':
                                statusLabel = 'Tiếp nhận';
                                break;
                              case 'Processing':
                                statusLabel = 'Đang xử lý';
                                break;
                              case 'Completed':
                                statusLabel = 'Đã hoàn thành';
                                break;
                              case 'Cancelled':
                                statusLabel = 'Đã hủy';
                                break;
                              default:
                                statusLabel = entry.key;
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _statusColor(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    total > 0
                                        ? '${(entry.value / total * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withAlpha(40)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết trạng thái',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ...data.entries.map(
                  (entry) {
                    String statusLabel;
                    switch (entry.key) {
                      case 'Received':
                        statusLabel = 'Tiếp nhận';
                        break;
                      case 'Processing':
                        statusLabel = 'Đang xử lý';
                        break;
                      case 'Completed':
                        statusLabel = 'Đã hoàn thành';
                        break;
                      case 'Cancelled':
                        statusLabel = 'Đã hủy';
                        break;
                      default:
                        statusLabel = entry.key;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _statusColor(entry.key),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            child: Text(
                              total > 0
                                  ? '(${(entry.value / total * 100).toStringAsFixed(1)}%)'
                                  : '(0%)',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$total sự vụ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
