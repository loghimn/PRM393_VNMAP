import 'package:flutter/material.dart';
import '../../models/province_model.dart';
import '../../services/database_service.dart';
import 'package:vietnam_geo_dashboard/utils/app_theme.dart';

class ProvinceComparison extends StatefulWidget {
  final List<ProvinceModel> provinces;

  const ProvinceComparison({super.key, required this.provinces});

  @override
  State<ProvinceComparison> createState() => _ProvinceComparisonState();
}

class _ProvinceComparisonState extends State<ProvinceComparison> {
  int _comparisonMode = 0;

  ProvinceModel? selectedProvince1;
  ProvinceModel? selectedProvince2;

  ProvinceModel? selectedProvinceForCommune1;
  ProvinceModel? selectedProvinceForCommune2;
  List<ProvinceModel> communes1 = [];
  List<ProvinceModel> communes2 = [];
  bool isLoadingCommunes1 = false;
  bool isLoadingCommunes2 = false;
  ProvinceModel? selectedCommune1;
  ProvinceModel? selectedCommune2;

  @override
  void initState() {
    super.initState();
    if (widget.provinces.isNotEmpty) {
      selectedProvince1 = widget.provinces[0];
      selectedProvinceForCommune1 = widget.provinces[0];
      if (widget.provinces.length > 1) {
        selectedProvince2 = widget.provinces[1];
        selectedProvinceForCommune2 = widget.provinces[1];
      } else {
        selectedProvinceForCommune2 = widget.provinces[0];
      }
    }
  }

  Future<void> _loadCommunesForProvince1(ProvinceModel province) async {
    setState(() {
      selectedProvinceForCommune1 = province;
      isLoadingCommunes1 = true;
      communes1 = [];
      selectedCommune1 = null;
    });

    try {
      final databaseService = DatabaseService();
      final fetched = await databaseService.fetchCommunesForProvince(
        province.name,
      );
      setState(() {
        communes1 = fetched;
        if (fetched.isNotEmpty) {
          if (selectedProvinceForCommune1 == selectedProvinceForCommune2 &&
              selectedCommune2 != null &&
              fetched.length > 1 &&
              fetched[0].ma == selectedCommune2!.ma) {
            selectedCommune1 = fetched[1];
          } else {
            selectedCommune1 = fetched[0];
          }
        }
        isLoadingCommunes1 = false;
      });
    } catch (e) {
      // ignore: avoid_print
      debugPrint("Error fetching communes for ${province.name}: $e");
      setState(() {
        isLoadingCommunes1 = false;
      });
    }
  }

  Future<void> _loadCommunesForProvince2(ProvinceModel province) async {
    setState(() {
      selectedProvinceForCommune2 = province;
      isLoadingCommunes2 = true;
      communes2 = [];
      selectedCommune2 = null;
    });

    try {
      final databaseService = DatabaseService();
      final fetched = await databaseService.fetchCommunesForProvince(
        province.name,
      );
      setState(() {
        communes2 = fetched;
        if (fetched.isNotEmpty) {
          if (selectedProvinceForCommune1 == selectedProvinceForCommune2 &&
              selectedCommune1 != null &&
              fetched.length > 1 &&
              fetched[0].ma == selectedCommune1!.ma) {
            selectedCommune2 = fetched[1];
          } else {
            selectedCommune2 = fetched[0];
          }
        }
        isLoadingCommunes2 = false;
      });
    } catch (e) {
      // ignore: avoid_print
      debugPrint("Error fetching communes for ${province.name}: $e");
      setState(() {
        isLoadingCommunes2 = false;
      });
    }
  }

  void _onComparisonModeChanged(int mode) {
    setState(() {
      _comparisonMode = mode;
    });
    if (mode == 1) {
      if ((selectedProvinceForCommune1 == null || communes1.isEmpty) && widget.provinces.isNotEmpty) {
        _loadCommunesForProvince1(selectedProvinceForCommune1 ?? widget.provinces[0]);
      }
      if ((selectedProvinceForCommune2 == null || communes2.isEmpty) && widget.provinces.isNotEmpty) {
        if (selectedProvinceForCommune2 != null) {
          _loadCommunesForProvince2(selectedProvinceForCommune2!);
        } else if (widget.provinces.length > 1) {
          _loadCommunesForProvince2(widget.provinces[1]);
        } else {
          _loadCommunesForProvince2(widget.provinces[0]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with title ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _comparisonMode == 0
                      ? Icons.compare_arrows
                      : Icons.swap_horiz,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _comparisonMode == 0
                    ? 'So Sánh Hai Tỉnh'
                    : 'So Sánh Hai Xã/Phường',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Mode Toggle ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onComparisonModeChanged(0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _comparisonMode == 0
                            ? AppColors.primaryGradient
                            : null,
                        color: _comparisonMode == 0 ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Tỉnh/Thành Phố',
                          style: TextStyle(
                            color: _comparisonMode == 0
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onComparisonModeChanged(1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _comparisonMode == 1
                            ? AppColors.primaryGradient
                            : null,
                        color: _comparisonMode == 1 ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Xã/Phường',
                          style: TextStyle(
                            color: _comparisonMode == 1
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_comparisonMode == 0) ...[
            // ── Province Selection ──
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Tỉnh 1',
                    value: selectedProvince1,
                    items: widget.provinces
                        .where((p) => p.name != selectedProvince2?.name)
                        .toList(),
                    color: AppColors.compareA,
                    onChanged: (value) {
                      setState(() {
                        selectedProvince1 = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Tỉnh 2',
                    value: selectedProvince2,
                    items: widget.provinces
                        .where((p) => p.name != selectedProvince1?.name)
                        .toList(),
                    color: AppColors.compareB,
                    onChanged: (value) {
                      setState(() {
                        selectedProvince2 = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
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
                icon: Icons.straighten,
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
          ] else ...[
            // ── Commune Mode ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdown(
                        label: 'Chọn Tỉnh/Thành phố 1',
                        value: selectedProvinceForCommune1,
                        items: widget.provinces,
                        color: AppColors.compareA,
                        onChanged: (value) {
                          if (value != null) {
                            _loadCommunesForProvince1(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingCommunes1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.compareA),
                          ),
                        )
                      else if (communes1.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Không có dữ liệu xã/phường.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        _buildDropdown(
                          label: 'Xã/Phường 1',
                          value: selectedCommune1,
                          items: selectedProvinceForCommune1 == selectedProvinceForCommune2
                              ? communes1.where((c) => c.ma != selectedCommune2?.ma).toList()
                              : communes1,
                          color: AppColors.compareA,
                          onChanged: (value) {
                            setState(() {
                              selectedCommune1 = value;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Column 2
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdown(
                        label: 'Chọn Tỉnh/Thành phố 2',
                        value: selectedProvinceForCommune2,
                        items: widget.provinces,
                        color: AppColors.compareB,
                        onChanged: (value) {
                          if (value != null) {
                            _loadCommunesForProvince2(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingCommunes2)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.compareB),
                          ),
                        )
                      else if (communes2.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Không có dữ liệu xã/phường.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        _buildDropdown(
                          label: 'Xã/Phường 2',
                          value: selectedCommune2,
                          items: selectedProvinceForCommune1 == selectedProvinceForCommune2
                              ? communes2.where((c) => c.ma != selectedCommune1?.ma).toList()
                              : communes2,
                          color: AppColors.compareB,
                          onChanged: (value) {
                            setState(() {
                              selectedCommune2 = value;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (selectedCommune1 != null && selectedCommune2 != null) ...[
              _buildMetricChart(
                title: 'Dân Số',
                icon: Icons.people_alt,
                val1: (selectedCommune1!.population ?? 0).toDouble(),
                val2: (selectedCommune2!.population ?? 0).toDouble(),
                unit: 'người',
                p1Name: '${selectedCommune1!.name} (${selectedCommune1!.parentTen ?? ''})',
                p2Name: '${selectedCommune2!.name} (${selectedCommune2!.parentTen ?? ''})',
              ),
              _buildMetricChart(
                title: 'Diện Tích',
                icon: Icons.straighten,
                val1: selectedCommune1!.areaKm2 ?? 0.0,
                val2: selectedCommune2!.areaKm2 ?? 0.0,
                unit: 'km²',
                p1Name: '${selectedCommune1!.name} (${selectedCommune1!.parentTen ?? ''})',
                p2Name: '${selectedCommune2!.name} (${selectedCommune2!.parentTen ?? ''})',
                isDecimal: true,
              ),
              _buildMetricChart(
                title: 'Mật Độ Dân Số',
                icon: Icons.density_medium,
                val1: selectedCommune1!.density ?? 0.0,
                val2: selectedCommune2!.density ?? 0.0,
                unit: 'người/km²',
                p1Name: '${selectedCommune1!.name} (${selectedCommune1!.parentTen ?? ''})',
                p2Name: '${selectedCommune2!.name} (${selectedCommune2!.parentTen ?? ''})',
                isDecimal: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required ProvinceModel? value,
    required List<ProvinceModel> items,
    required Color color,
    required ValueChanged<ProvinceModel?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: AppColors.cardShadow,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProvinceModel>(
              value: value,
              dropdownColor: AppColors.surfaceBackground,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              items: items.map((province) {
                return DropdownMenuItem(
                  value: province,
                  child: Text(
                    province.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: AppColors.cardShadow,
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
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (ratioText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ratioText,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Province 1
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
                              color: isP1Winner
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight: isP1Winner
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isP1Winner) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.compareA,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${_formatNumber(val1, isDecimal: isDecimal)} $unit',
                    style: TextStyle(
                      color: isP1Winner
                          ? AppColors.compareA
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * pct1,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: isP1Winner
                              ? [
                                  BoxShadow(
                                    color: AppColors.compareA.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Province 2
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
                              color: isP2Winner
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight: isP2Winner
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isP2Winner) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.compareB,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${_formatNumber(val2, isDecimal: isDecimal)} $unit',
                    style: TextStyle(
                      color: isP2Winner
                          ? AppColors.compareB
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * pct2,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: isP2Winner
                              ? [
                                  BoxShadow(
                                    color: AppColors.compareB.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
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
