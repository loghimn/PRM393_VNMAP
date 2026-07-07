enum IncidentStatus {
  received,
  processing,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case IncidentStatus.received:
        return 'Received';
      case IncidentStatus.processing:
        return 'Processing';
      case IncidentStatus.completed:
        return 'Completed';
      case IncidentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get shortName {
    switch (this) {
      case IncidentStatus.received:
        return 'New';
      case IncidentStatus.processing:
        return 'Processing';
      case IncidentStatus.completed:
        return 'Completed';
      case IncidentStatus.cancelled:
        return 'Cancelled';
    }
  }

  static IncidentStatus fromString(String? value) {
    switch (value) {
      case 'processing':
        return IncidentStatus.processing;
      case 'completed':
        return IncidentStatus.completed;
      case 'cancelled':
        return IncidentStatus.cancelled;
      default:
        return IncidentStatus.received;
    }
  }

  String get dbValue {
    switch (this) {
      case IncidentStatus.received:
        return 'received';
      case IncidentStatus.processing:
        return 'processing';
      case IncidentStatus.completed:
        return 'completed';
      case IncidentStatus.cancelled:
        return 'cancelled';
    }
  }
}

class Incident {
  final int? id;
  final String incidentCode;
  final String title;
  final String? description;
  final String? address;
  final String? neighborhood;
  final String? ward;
  final String? district;
  final String? city;
  final double? longitude;
  final double? latitude;
  final int? householdId;
  final String? headOfHousehold;
  final String? phone;
  final IncidentStatus status;
  final String? handler;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedDate;

  Incident({
    this.id,
    required this.incidentCode,
    required this.title,
    this.description,
    this.address,
    this.neighborhood,
    this.ward,
    this.district,
    this.city,
    this.longitude,
    this.latitude,
    this.householdId,
    this.headOfHousehold,
    this.phone,
    this.status = IncidentStatus.received,
    this.handler,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.completedDate,
  });

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add('NB $neighborhood');
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      incidentCode: json['incident_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      ward: json['ward']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      longitude: json['longitude'] is double
          ? json['longitude']
          : double.tryParse('${json['longitude']}'),
      latitude: json['latitude'] is double
          ? json['latitude']
          : double.tryParse('${json['latitude']}'),
      householdId: json['household_id'] is int
          ? json['household_id']
          : int.tryParse('${json['household_id']}'),
      headOfHousehold: json['head_of_household']?.toString(),
      phone: json['phone']?.toString(),
      status: IncidentStatus.fromString(json['status']?.toString()),
      handler: json['handler']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'incident_code': incidentCode,
      'title': title,
      'description': description,
      'address': address,
      'neighborhood': neighborhood,
      'ward': ward,
      'district': district,
      'city': city,
      'longitude': longitude,
      'latitude': latitude,
      'household_id': householdId,
      'head_of_household': headOfHousehold,
      'phone': phone,
      'status': status.dbValue,
      'handler': handler,
      'notes': notes,
      if (completedDate != null)
        'completed_date': completedDate!.toIso8601String(),
    };
  }
}
