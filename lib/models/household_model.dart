class Household {
  final int? id;
  final String householdCode;
  final String headOfHousehold;
  final String? houseNumber;
  final String? street;
  final String? neighborhood;
  final String? ward;
  final String? district;
  final String? city;
  final String? phone;
  final String? email;
  final int? population;
  final String? notes;
  final double? longitude;
  final double? latitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Household({
    this.id,
    required this.householdCode,
    required this.headOfHousehold,
    this.houseNumber,
    this.street,
    this.neighborhood,
    this.ward,
    this.district,
    this.city,
    this.phone,
    this.email,
    this.population,
    this.notes,
    this.longitude,
    this.latitude,
    this.createdAt,
    this.updatedAt,
  });

  String get fullAddress {
    final parts = <String>[];
    if (houseNumber != null && houseNumber!.isNotEmpty) parts.add(houseNumber!);
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add('NB $neighborhood');
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      householdCode: json['household_code']?.toString() ?? '',
      headOfHousehold: json['head_of_household']?.toString() ?? '',
      houseNumber: json['house_number']?.toString(),
      street: json['street']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      ward: json['ward']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      population: json['population'] is int
          ? json['population']
          : int.tryParse('${json['population']}'),
      notes: json['notes']?.toString(),
      longitude: json['longitude'] is double
          ? json['longitude']
          : double.tryParse('${json['longitude']}'),
      latitude: json['latitude'] is double
          ? json['latitude']
          : double.tryParse('${json['latitude']}'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'household_code': householdCode,
      'head_of_household': headOfHousehold,
      'house_number': houseNumber,
      'street': street,
      'neighborhood': neighborhood,
      'ward': ward,
      'district': district,
      'city': city,
      'phone': phone,
      'email': email,
      'population': population,
      'notes': notes,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'household_code': householdCode,
      'head_of_household': headOfHousehold,
      'house_number': houseNumber,
      'street': street,
      'neighborhood': neighborhood,
      'ward': ward,
      'district': district,
      'city': city,
      'phone': phone,
      'email': email,
      'population': population,
      'notes': notes,
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
