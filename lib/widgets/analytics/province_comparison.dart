import 'package:flutter/material.dart';
import '../../models/province_model.dart';
import '../../services/database_service.dart';

class ProvinceComparison extends StatefulWidget {
  final List<ProvinceModel> provinces;

  const ProvinceComparison({super.key, required this.provinces});

  @override
  State<ProvinceComparison> createState() => _ProvinceComparisonState();
}

class _ProvinceComparisonState extends State<ProvinceComparison> {
  // Mode selection: 0 = Province, 1 = Commune
  int _comparisonMode = 0;

  // States for Province comparison (existing)
  ProvinceModel? selectedProvince1;
  ProvinceModel? selectedProvince2;

  // States for Commune comparison (new)
  ProvinceModel? selectedProvinceForCommunes;
  List<ProvinceModel> communes = [];
  bool isLoadingCommunes = false;
  ProvinceModel? selectedCommune1;
  ProvinceModel? selectedCommune2;

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

  Future<void> _loadCommunesForProvince(ProvinceModel province) async {
    setState(() {
      selectedProvinceForCommunes = province;
      isLoadingCommunes = true;
      communes = [];
      selectedCommune1 = null;
      selectedCommune2 = null;
    });

    try {
      final databaseService = DatabaseService();
      final fetched = await databaseService.fetchCommunesForProvince(province.name);
      setState(() {
        communes = fetched;
        if (fetched.isNotEmpty) {
          selectedCommune1 = fetched[0];
          if (fetched.length > 1) {
            selectedCommune2 = fetched[1];
          }
        }
        isLoadingCommunes = false;
      });
    } catch (e) {
      print("Error fetching communes for ${province.name}: $e");
      setState(() {
        isLoadingCommunes = false;
      });
    }
  }

  void _onComparisonModeChanged(int mode) {
    setState(() {
      _comparisonMode = mode;
    });
    if (mode == 1 && selectedProvinceForCommunes == null && widget.provinces.isNotEmpty) {
      _loadCommunesForProvince(widget.provinces[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _comparisonMode == 0 ? 'So Sánh Hai Tỉnh' : 'So Sánh Hai Xã/Phường',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mode Toggle Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xff1e293b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onComparisonModeChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _comparisonMode == 0
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _comparisonMode == 0
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Tỉnh/Thành Phố',
                          style: TextStyle(
                            color: _comparisonMode == 0 ? Colors.blueAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _comparisonMode == 1
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _comparisonMode == 1
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Xã/Phường',
                          style: TextStyle(
                            color: _comparisonMode == 1 ? Colors.blueAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
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
          ] else ...[
            // Commune Selection / Loading
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn Tỉnh/Thành phố',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButton<ProvinceModel>(
                  value: selectedProvinceForCommunes,
                  dropdownColor: const Color(0xff0f172a),
                  isExpanded: true,
                  items: widget.provinces.map((province) {
                    return DropdownMenuItem(
                      value: province,
                      child: Text(
                        province.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _loadCommunesForProvince(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingCommunes)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              )
            else if (communes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Không tìm thấy dữ liệu xã/phường cho tỉnh/thành phố này.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xã/Phường 1',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<ProvinceModel>(
                          value: selectedCommune1,
                          dropdownColor: const Color(0xff0f172a),
                          isExpanded: true,
                          items: communes
                              .where((c) => c.name != selectedCommune2?.name)
                              .map((commune) {
                            return DropdownMenuItem(
                              value: commune,
                              child: Text(
                                commune.name,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xã/Phường 2',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<ProvinceModel>(
                          value: selectedCommune2,
                          dropdownColor: const Color(0xff0f172a),
                          isExpanded: true,
                          items: communes
                              .where((c) => c.name != selectedCommune1?.name)
                              .map((commune) {
                            return DropdownMenuItem(
                              value: commune,
                              child: Text(
                                commune.name,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
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
              // Commune Comparison Dashboard
              if (selectedCommune1 != null && selectedCommune2 != null) ...[
                _buildMetricChart(
                  title: 'Dân Số',
                  icon: Icons.people_alt,
                  val1: (selectedCommune1!.population ?? 0).toDouble(),
                  val2: (selectedCommune2!.population ?? 0).toDouble(),
                  unit: 'người',
                  p1Name: selectedCommune1!.name,
                  p2Name: selectedCommune2!.name,
                ),
                _buildMetricChart(
                  title: 'Diện Tích',
                  icon: Icons.landscape,
                  val1: selectedCommune1!.areaKm2 ?? 0.0,
                  val2: selectedCommune2!.areaKm2 ?? 0.0,
                  unit: 'km²',
                  p1Name: selectedCommune1!.name,
                  p2Name: selectedCommune2!.name,
                  isDecimal: true,
                ),
                _buildMetricChart(
                  title: 'Mật Độ Dân Số',
                  icon: Icons.density_medium,
                  val1: selectedCommune1!.density ?? 0.0,
                  val2: selectedCommune2!.density ?? 0.0,
                  unit: 'người/km²',
                  p1Name: selectedCommune1!.name,
                  p2Name: selectedCommune2!.name,
                  isDecimal: true,
                ),
              ],
            ],
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
