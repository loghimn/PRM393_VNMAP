import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/household_model.dart';
import '../../providers/household_provider.dart';
import '../../services/database_service.dart';

class HouseholdFormScreen extends StatefulWidget {
  final Household? household;
  const HouseholdFormScreen({super.key, this.household});
  @override
  State<HouseholdFormScreen> createState() => _HouseholdFormScreenState();
}

class _HouseholdFormScreenState extends State<HouseholdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  late final TextEditingController _headOfHouseholdController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _streetController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _wardController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _populationController;
  late final TextEditingController _notesController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _latitudeController;
  bool _isSaving = false;
  bool get _isEditing => widget.household != null;
  List<String> _wards = [];
  List<Map<String, String>> _cities = [];

  @override
  void initState() {
    super.initState();
    final household = widget.household;
    _headOfHouseholdController = TextEditingController(
      text: household?.headOfHousehold ?? '',
    );
    _houseNumberController = TextEditingController(
      text: household?.houseNumber ?? '',
    );
    _streetController = TextEditingController(text: household?.street ?? '');
    _neighborhoodController = TextEditingController(
      text: household?.neighborhood ?? '',
    );
    _wardController = TextEditingController(text: household?.ward ?? '');
    _districtController = TextEditingController(
      text: household?.district ?? '',
    );
    _cityController = TextEditingController(text: household?.city ?? '');
    _phoneController = TextEditingController(text: household?.phone ?? '');
    _emailController = TextEditingController(text: household?.email ?? '');
    _populationController = TextEditingController(
      text: household?.population?.toString() ?? '',
    );
    _notesController = TextEditingController(text: household?.notes ?? '');
    _longitudeController = TextEditingController(
      text: household?.longitude?.toString() ?? '',
    );
    _latitudeController = TextEditingController(
      text: household?.latitude?.toString() ?? '',
    );
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final cities = await _db.fetchDistinctCities();
    List<String> wards = [];
    final selectedCity = _cityController.text.trim();
    if (selectedCity.isNotEmpty) {
      final match = cities.firstWhere(
        (c) => c['name'] == selectedCity,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        wards = await _db.fetchCommunesForParentCode(match['code']!);
      }
    }
    if (mounted)
      setState(() {
        _cities = cities;
        _wards = wards;
      });
  }

  Future<void> _onCityChanged(String name) async {
    if (name.isEmpty) return;
    final match = _cities.firstWhere(
      (c) => c['name'] == name,
      orElse: () => {},
    );
    if (match.isEmpty) return;
    final wards = await _db.fetchCommunesForParentCode(match['code']!);
    if (mounted)
      setState(() {
        _wards = wards;
        _wardController.clear();
      });
  }

  @override
  void dispose() {
    _headOfHouseholdController.dispose();
    _houseNumberController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _populationController.dispose();
    _notesController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final h = Household(
        id: widget.household?.id,
        householdCode: widget.household?.householdCode ?? '',
        headOfHousehold: _headOfHouseholdController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        street: _streetController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        ward: _wardController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        population: int.tryParse(_populationController.text.trim()),
        notes: _notesController.text.trim(),
        longitude: double.tryParse(_longitudeController.text.trim()),
        latitude: double.tryParse(_latitudeController.text.trim()),
      );

      final provider = context.read<HouseholdProvider>();
      final ok = _isEditing
          ? await provider.update(h)
          : await provider.create(h);

      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lưu thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          final errMsg = provider.error ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $errMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _drop(
    String label,
    TextEditingController ctrl,
    List<String> items, {
    void Function(String)? onChanged,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (t) => t.text.isEmpty
          ? items
          : items.where((e) => e.toLowerCase().contains(t.text.toLowerCase())),
      onSelected: (v) {
        ctrl.text = v;
        onChanged?.call(v);
      },
      fieldViewBuilder: (ctx, c, f, _) => TextFormField(
        controller: c,
        focusNode: f,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Household' : 'Create Household'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _s('Basic Info'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _headOfHouseholdController,
                decoration: const InputDecoration(
                  labelText: 'Head of Household *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _s('Location'),
              const SizedBox(height: 8),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _cityController.text),
                optionsBuilder: (tv) {
                  final names = _cities.map((c) => c['name']!).toList();
                  return tv.text.isEmpty
                      ? names
                      : names.where(
                          (e) =>
                              e.toLowerCase().contains(tv.text.toLowerCase()),
                        );
                },
                onSelected: (v) {
                  _cityController.text = v;
                  _onCityChanged(v);
                },
                fieldViewBuilder: (ctx, c, f, _) => TextFormField(
                  controller: c,
                  focusNode: f,
                  decoration: const InputDecoration(
                    labelText: 'City/Province',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _drop('Ward/Commune', _wardController, _wards),
              const SizedBox(height: 12),
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(
                  labelText: 'Neighborhood',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _houseNumberController,
                decoration: const InputDecoration(
                  labelText: 'House Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _s('Contact'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              _s('Household Info'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _populationController,
                decoration: const InputDecoration(
                  labelText: 'Number of Members',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _s('Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Update' : 'Save',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _s(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey,
    ),
  );
}
