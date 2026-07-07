import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/province_model.dart';
import '../../providers/province_provider.dart';
import '../../utils/app_theme.dart';

class ProvinceListPanel extends StatelessWidget {
  final bool showSearch;

  const ProvinceListPanel({super.key, this.showSearch = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvinceProvider>(
      builder: (context, provider, child) {
        final provinces = provider.provinces;
        if (provinces.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sort by density descending
        final sorted = List<ProvinceModel>.from(provinces)
          ..sort((a, b) => (b.density ?? 0).compareTo(a.density ?? 0));

        // Find max density for progress bar scaling
        final maxDensity = sorted.isNotEmpty
            ? (sorted.first.density ?? 1)
            : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với title + search icon
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.format_list_numbered_rtl,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Xếp Hạng Mật Độ Dân Số',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${sorted.length} tỉnh',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Danh sách tỉnh
            Expanded(
              child: ListView.separated(
                itemCount: sorted.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) =>
                    Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final p = sorted[index];
                  final density = p.density ?? 0;
                  final rank = index + 1;
                  final double barFraction = maxDensity > 0
                      ? density / maxDensity
                      : 0.0;

                  // Medal colors for top 3
                  Color? rankColor;
                  IconData? rankIcon;
                  if (rank == 1) {
                    rankColor = const Color(0xFFF59E0B);
                    rankIcon = Icons.emoji_events;
                  } else if (rank == 2) {
                    rankColor = const Color(0xFF94A3B8);
                    rankIcon = Icons.emoji_events;
                  } else if (rank == 3) {
                    rankColor = const Color(0xFFCD7F32);
                    rankIcon = Icons.emoji_events;
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        provider.selectProvince(p);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            // Rank badge
                            SizedBox(
                              width: 28,
                              child: rankIcon != null
                                  ? Icon(rankIcon, color: rankColor, size: 18)
                                  : Text(
                                      '$rank',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            // Province name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Density bar
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        height: 4,
                                        width: constraints.maxWidth,
                                        decoration: BoxDecoration(
                                          color: AppColors.border.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: barFraction.clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppColors.primaryGradient,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Density value
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${density.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
