class DiaDiemCongCong {
  final int? id;
  final String ten;
  final String? loai;
  final String? diaChi;
  final double? kinhDo;
  final double? viDo;
  final String? moTa;
  final String? ghiChu;
  final DateTime? createdAt;

  DiaDiemCongCong({
    this.id,
    required this.ten,
    this.loai,
    this.diaChi,
    this.kinhDo,
    this.viDo,
    this.moTa,
    this.ghiChu,
    this.createdAt,
  });

  factory DiaDiemCongCong.fromJson(Map<String, dynamic> json) {
    return DiaDiemCongCong(
      id: json['id'] as int?,
      ten: json['ten'] as String? ?? '',
      loai: json['loai'] as String?,
      diaChi: json['dia_chi'] as String?,
      kinhDo: (json['kinh_do'] as num?)?.toDouble(),
      viDo: (json['vi_do'] as num?)?.toDouble(),
      moTa: json['mo_ta'] as String?,
      ghiChu: json['ghi_chu'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'ten': ten,
        'loai': loai,
        'dia_chi': diaChi,
        'kinh_do': kinhDo,
        'vi_do': viDo,
        'mo_ta': moTa,
        'ghi_chu': ghiChu,
      };
}