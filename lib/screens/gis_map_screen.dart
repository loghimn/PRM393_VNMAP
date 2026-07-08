import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/household_provider.dart';
import '../providers/incident_provider.dart';
import '../models/household_model.dart';
import '../models/incident_model.dart';

class GisMapScreen extends StatefulWidget {
  const GisMapScreen({super.key});

  @override
  State<GisMapScreen> createState() => _GisMapScreenState();
}

class _GisMapScreenState extends State<GisMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  // Default center: Vietnam
  static const LatLng _defaultCenter = LatLng(16.0, 108.0);
  static const double _defaultZoom = 6.0;

  // Filter states
  bool _showHouseholds = true;
  bool _showIncidents = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final householdProvider = context.read<HouseholdProvider>();
    final incidentProvider = context.read<IncidentProvider>();
    
    await Future.wait([
      householdProvider.loadItems(),
      incidentProvider.loadItems(),
    ]);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Bản đồ GIS'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          // Legend button
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showLegend,
            tooltip: 'Chú thích',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                _onMapTapped(point);
              },
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vietnam_geo_dashboard.app',
                maxZoom: 19,
              ),
              
              // Marker layer for households and incidents
              MarkerLayer(
                markers: [
                  ..._buildHouseholdMarkers(),
                  ..._buildIncidentMarkers(),
                ],
              ),
            ],
          ),

          // Top search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white54, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Tìm hộ dân, khu phố, địa điểm...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _onSearch,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom filter bar
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Card(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip(
                      icon: Icons.home,
                      label: 'Hộ dân',
                      active: _showHouseholds,
                      onTap: () => setState(() => _showHouseholds = !_showHouseholds),
                      activeColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      icon: Icons.warning,
                      label: 'Sự vụ',
                      active: _showIncidents,
                      onTap: () => setState(() => _showIncidents = !_showIncidents),
                      activeColor: Colors.orange,
                    ),
                    const Spacer(),
                    Text(
                      '${_getTotalMarkers()} điểm',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildHouseholdMarkers() {
    if (!_showHouseholds) return [];
    final provider = context.watch<HouseholdProvider>();
    final households = provider.items;
    return households
        .where((h) => h.latitude != null && h.longitude != null)
        .map((h) {
      return Marker(
        point: LatLng(h.latitude!, h.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showHouseholdDetail(h),
          child: const Icon(
            Icons.home,
            color: Color(0xFF3B82F6),
            size: 30,
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildIncidentMarkers() {
    if (!_showIncidents) return [];
    final provider = context.watch<IncidentProvider>();
    final incidents = provider.items;
    return incidents
        .where((i) => i.latitude != null && i.longitude != null)
        .map((i) {
      final color = _getIncidentColor(i.status);
      return Marker(
        point: LatLng(i.latitude!, i.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showIncidentDetail(i),
          child: Icon(Icons.warning, color: color, size: 30),
        ),
      );
    }).toList();
  }

  Color _getIncidentColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.received:
        return Colors.orange;
      case IncidentStatus.processing:
        return const Color(0xFF3B82F6);
      case IncidentStatus.completed:
        return Colors.green;
      case IncidentStatus.cancelled:
        return Colors.grey;
    }
  }

  int _getTotalMarkers() {
    int count = 0;
    if (_showHouseholds) {
      final hProvider = context.read<HouseholdProvider>();
      count += hProvider.items.where((h) => h.latitude != null && h.longitude != null).length;
    }
    if (_showIncidents) {
      final iProvider = context.read<IncidentProvider>();
      count += iProvider.items.where((i) => i.latitude != null && i.longitude != null).length;
    }
    return count;
  }

  void _onMapTapped(LatLng point) {
    // TODO: Add marker or select location
  }

  void _onSearch(String query) {
    // Perform search
    setState(() {});
  }

  void _showHouseholdDetail(Household household) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home, color: Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    household.headOfHousehold ?? 'Hộ dân',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Mã hộ', household.householdCode),
            _detailRow('Địa chỉ', household.fullAddress),
            _detailRow('Số điện thoại', household.phone ?? '--'),
    if (household.latitude != null && household.longitude != null) ...[
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(ctx),
          icon: const Icon(Icons.navigation, size: 18),
          label: const Text('Xem vị trí'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ] else
      const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetail(Incident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: _getIncidentColor(incident.status)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    incident.title ?? 'Sự vụ',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Mã sự vụ', incident.incidentCode),
            _detailRow('Trạng thái', incident.status.displayName),
            _detailRow('Địa chỉ', incident.address ?? '--'),
            _detailRow('Người xử lý', incident.handler ?? 'Chưa phân công'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value ?? '--',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : Colors.white54,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Chú thích', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(Icons.home, const Color(0xFF3B82F6), 'Hộ gia đình'),
            const SizedBox(height: 12),
            _legendItem(Icons.warning, Colors.orange, 'Sự vụ - Tiếp nhận'),
            _legendItem(Icons.warning, const Color(0xFF3B82F6), 'Sự vụ - Đang xử lý'),
            _legendItem(Icons.warning, Colors.green, 'Sự vụ - Hoàn thành'),
            _legendItem(Icons.warning, Colors.grey, 'Sự vụ - Đã hủy'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}