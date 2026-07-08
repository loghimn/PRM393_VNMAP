import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident_model.dart';
import '../../providers/incident_provider.dart';
import '../../providers/household_provider.dart';
import '../../services/database_service.dart';

class IncidentFormScreen extends StatefulWidget {
  final Incident? incident;
  final int? householdId;
  const IncidentFormScreen({super.key, this.incident, this.householdId});
  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _wardController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _handlerController;
  late final TextEditingController _notesController;
  late final TextEditingController _headOfHouseholdController;
  late final TextEditingController _phoneController;
  int? _householdId;
  bool _isSaving = false;
  bool get _isEditing => widget.incident != null;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];

  @override
  void initState() {
    super.initState();
    final inc = widget.incident;
    _householdId = widget.householdId ?? inc?.householdId;
    _titleController = TextEditingController(text: inc?.title ?? '');
    _descriptionController = TextEditingController(text: inc?.description ?? '');
    _addressController = TextEditingController(text: inc?.address ?? '');
    _neighborhoodController = TextEditingController(text: inc?.neighborhood ?? '');
    _wardController = TextEditingController(text: inc?.ward ?? '');
    _districtController = TextEditingController(text: inc?.district ?? '');
    _cityController = TextEditingController(text: inc?.city ?? '');
    _handlerController = TextEditingController(text: inc?.handler ?? '');
    _notesController = TextEditingController(text: inc?.notes ?? '');
    _headOfHouseholdController = TextEditingController(text: inc?.headOfHousehold ?? '');
    _phoneController = TextEditingController(text: inc?.phone ?? '');
    _loadDropdownData();
    if (_householdId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HouseholdProvider>().loadItems();
      });
    }
  }

  Future<void> _loadDropdownData() async {
    final cities = await _db.fetchDistinctCities();
    List<String> wards = [];
    final sc = _cityController.text.trim();
    if (sc.isNotEmpty) {
      final m = cities.firstWhere((c) => c['name'] == sc, orElse: () => {});
      if (m.isNotEmpty) wards = await _db.fetchCommunesForParentCode(m['code']!);
    }
    if (mounted) setState(() { _cities = cities; _wards = wards; });
  }

  Future<void> _onCityChanged(String name) async {
    if (name.isEmpty) return;
    final m = _cities.firstWhere((c) => c['name'] == name, orElse: () => {});
    if (m.isEmpty) return;
    final wards = await _db.fetchCommunesForParentCode(m['code']!);
    if (mounted) setState(() { _wards = wards; _wardController.clear(); });
  }

  @override
  void dispose() {
    _titleController.dispose(); _descriptionController.dispose();
    _addressController.dispose(); _neighborhoodController.dispose();
    _wardController.dispose(); _districtController.dispose();
    _cityController.dispose(); _handlerController.dispose();
    _notesController.dispose(); _headOfHouseholdController.dispose();
    _phoneController.dispose(); super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    String code = _isEditing ? widget.incident!.incidentCode : await _db.generateIncidentCode();
    final inc = Incident(id: widget.incident?.id, incidentCode: code,
      title: _titleController.text.trim(), description: _descriptionController.text.trim(),
      address: _addressController.text.trim(), neighborhood: _neighborhoodController.text.trim(),
      ward: _wardController.text.trim(), district: _districtController.text.trim(),
      city: _cityController.text.trim(), handler: _handlerController.text.trim(),
      notes: _notesController.text.trim(), headOfHousehold: _headOfHouseholdController.text.trim(),
      phone: _phoneController.text.trim(), householdId: _householdId,
    );
    final provider = context.read<IncidentProvider>();
    final ok = _isEditing ? await provider.update(inc) : await provider.create(inc);
    if (mounted) { setState(() => _isSaving = false); if (ok) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Updated' : 'Created'))); Navigator.pop(context); } }
  }

  Widget _drop(String label, TextEditingController ctrl, List<String> items, {void Function(String)? onChanged}) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (t) => t.text.isEmpty ? items : items.where((e) => e.toLowerCase().contains(t.text.toLowerCase())),
      onSelected: (v) { ctrl.text = v; onChanged?.call(v); },
      fieldViewBuilder: (ctx, c, f, _) => TextFormField(controller: c, focusNode: f,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.arrow_drop_down))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Incident' : 'Create Incident')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _s('Incident Info'), const SizedBox(height: 8),
          TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          _s('Location'), const SizedBox(height: 8),
          _drop('City/Province', _cityController, _cities.map((c) => c['name']!).toList(), onChanged: _onCityChanged),
          const SizedBox(height: 12),
          _drop('Ward/Commune', _wardController, _wards),
          const SizedBox(height: 12),
          TextFormField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: 'Neighborhood', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _districtController, decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          _s('Household Info'), const SizedBox(height: 8),
          TextFormField(controller: _headOfHouseholdController, decoration: const InputDecoration(labelText: 'Head of Household', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          _s('Assignment'), const SizedBox(height: 8),
          TextFormField(controller: _handlerController, decoration: const InputDecoration(labelText: 'Handler', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          _s('Notes'), const SizedBox(height: 8),
          TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(onPressed: _isSaving ? null : _save,
              child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Update' : 'Save', style: const TextStyle(fontSize: 16)))),
          const SizedBox(height: 16),
        ],
      ))),
    );
  }

  Widget _s(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));
}
