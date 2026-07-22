class DaiDienModel {
  final int? id;
  final String hoTen;
  final String? soDienThoai;
  final String? email;
  final String? diaChi;
  final int? khuPhoId;
  final String? tenKhuPho;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DaiDienModel({
    this.id,
    required this.hoTen,
    this.soDienThoai,
    this.email,
    this.diaChi,
    this.khuPhoId,
    this.tenKhuPho,
    this.createdAt,
    this.updatedAt,
  });

  factory DaiDienModel.fromJson(Map<String, dynamic> json) {
    return DaiDienModel(
      id: json['id'] as int?,
      hoTen: json['ho_ten'] as String? ?? '',
      soDienThoai: json['so_dien_thoai'] as String?,
      email: json['email'] as String?,
      diaChi: json['dia_chi'] as String?,
      khuPhoId: json['khu_pho_id'] as int?,
      tenKhuPho: json['ten_khu_pho'] as String?,
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
      'ho_ten': hoTen,
      'so_dien_thoai': soDienThoai,
      'email': email,
      'dia_chi': diaChi,
      'khu_pho_id': khuPhoId,
    };
  }
}