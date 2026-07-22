class KhuPhoModel {
  final int? id;
  final String tenKhuPho;
  final String? moTa;
  final String? diaChi;
  final String? parentTen; // Tên phường/xã (từ bảng communes)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KhuPhoModel({
    this.id,
    required this.tenKhuPho,
    this.moTa,
    this.diaChi,
    this.parentTen,
    this.createdAt,
    this.updatedAt,
  });

  factory KhuPhoModel.fromJson(Map<String, dynamic> json) {
    return KhuPhoModel(
      id: json['id'] as int?,
      tenKhuPho: json['ten_khu_pho'] as String? ?? '',
      moTa: json['mo_ta'] as String?,
      diaChi: json['dia_chi'] as String?,
      parentTen: json['parent_ten'] as String?,
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
      'ten_khu_pho': tenKhuPho,
      'mo_ta': moTa,
      'dia_chi': diaChi,
      'parent_ten': parentTen,
    };
  }
}