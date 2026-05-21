import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';

class ProvinceDetailPanel extends StatelessWidget {
  final ProvinceModel? province;

  const ProvinceDetailPanel({super.key, required this.province});

  @override
  Widget build(BuildContext context) {
    if (province == null) {
      return Container(
        color: const Color(0xff111827),
        child: const Center(
          child: Text(
            "Select a province",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xff111827),
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            province!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _buildInfo("Code", province!.ma),
          _buildInfo("Area", "${province!.areaKm2} km²"),
          _buildInfo("Population", province!.population),
          _buildInfo("Density", province!.density),
          _buildInfo("Capital", province!.capital),
          _buildInfo("Region", province!.macroRegion),

          const SizedBox(height: 24),

          const Divider(color: Colors.white24),

          const SizedBox(height: 24),

          Text(
            "Decree",
            style: TextStyle(
              color: Colors.orange.shade300,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            province!.decree ?? "-",
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              "$value",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
