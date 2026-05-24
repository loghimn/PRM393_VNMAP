import 'package:flutter/material.dart';
import '../../models/province_model.dart';

class ProvinceComparison extends StatefulWidget {
  final List<ProvinceModel> provinces;

  const ProvinceComparison({Key? key, required this.provinces})
    : super(key: key);

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
          // Comparison Table
          if (selectedProvince1 != null && selectedProvince2 != null)
            _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final p1 = selectedProvince1!;
    final p2 = selectedProvince2!;

    final rows = [
      {'label': 'Tên Tỉnh', 'p1': p1.name, 'p2': p2.name},
      {
        'label': 'Dân Số',
        'p1': '${p1.population ?? 'N/A'}',
        'p2': '${p2.population ?? 'N/A'}',
      },
      {
        'label': 'Mã Tỉnh',
        'p1': '${p1.ma ?? 'N/A'}',
        'p2': '${p2.ma ?? 'N/A'}',
      },
      {
        'label': 'Khu Vực',
        'p1': '${p1.macroRegion ?? 'N/A'}',
        'p2': '${p2.macroRegion ?? 'N/A'}',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            color: Colors.blue.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Thuộc Tính',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    p1.name,
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    p2.name,
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Data Rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isAlternate = index.isEven;

            return Container(
              color: isAlternate
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['label'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['p1'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['p2'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
