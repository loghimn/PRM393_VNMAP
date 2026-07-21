class HouseholdRequest {
  final int? id;
  final int userId;
  final String headOfHousehold;
  final String? houseNumber;
  final String? street;
  final String? neighborhood;
  final String? ward;
  final String? district;
  final String? city;
  final String phone;
  final String? email;
  final int? population;
  final String? notes;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;

  HouseholdRequest({
    this.id,
    required this.userId,
    required this.headOfHousehold,
    this.houseNumber,
    this.street,
    this.neighborhood,
    this.ward,
    this.district,
    this.city,
    required this.phone,
    this.email,
    this.population,
    this.notes,
    this.status = 'pending',
    this.adminNote,
    this.createdAt,
    this.updatedAt,
    this.imageUrls = const [],
  });

  factory HouseholdRequest.fromJson(Map<String, dynamic> json) {
    return HouseholdRequest(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      headOfHousehold: json['head_of_household']?.toString() ?? '',
      houseNumber: json['house_number']?.toString(),
      street: json['street']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      ward: json['ward']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      population: json['population'] is int
          ? json['population']
          : int.tryParse('${json['population']}'),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      adminNote: json['admin_note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      imageUrls: json['image_urls'] is List
          ? (json['image_urls'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }

  String get fullAddress => [
    if (houseNumber != null && houseNumber!.isNotEmpty) houseNumber,
    if (street != null && street!.isNotEmpty) street,
    if (neighborhood != null && neighborhood!.isNotEmpty) neighborhood,
    if (ward != null && ward!.isNotEmpty) ward,
    if (district != null && district!.isNotEmpty) district,
    if (city != null && city!.isNotEmpty) city,
  ].join(', ');

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
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
      'status': status,
      'admin_note': adminNote,
      'image_urls': imageUrls,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
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
      'status': status,
      'admin_note': adminNote,
      'image_urls': imageUrls,
    };
  }
}
