class DiaDiemLichSu {
  final int? id;
  final String ten;
  final String? loaiDiTich;
  final String? diaChi;
  final double? kinhDo;
  final double? viDo;
  final String? moTa;
  final String? thoiKy;
  final String? imageUrl;
  final String? ghiChu;
  final DateTime? createdAt;

  DiaDiemLichSu({
    this.id,
    required this.ten,
    this.loaiDiTich,
    this.diaChi,
    this.kinhDo,
    this.viDo,
    this.moTa,
    this.thoiKy,
    this.imageUrl,
    this.ghiChu,
    this.createdAt,
  });

  factory DiaDiemLichSu.fromJson(Map<String, dynamic> json) {
    return DiaDiemLichSu(
      id: json['id'] as int?,
      ten: json['ten'] as String? ?? '',
      loaiDiTich: json['loai_di_tich'] as String?,
      diaChi: json['dia_chi'] as String?,
      kinhDo: (json['kinh_do'] as num?)?.toDouble(),
      viDo: (json['vi_do'] as num?)?.toDouble(),
      moTa: json['mo_ta'] as String?,
      thoiKy: json['thoi_ky'] as String?,
      imageUrl: json['image_url'] as String?,
      ghiChu: json['ghi_chu'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'ten': ten,
    'loai_di_tich': loaiDiTich,
    'dia_chi': diaChi,
    'kinh_do': kinhDo,
    'vi_do': viDo,
    'mo_ta': moTa,
    'thoi_ky': thoiKy,
    'image_url': imageUrl,
    'ghi_chu': ghiChu,
  };
}
