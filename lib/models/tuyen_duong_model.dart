class TuyenDuong {
  final int? id;
  final String ten;
  final String? loai;
  final String? diaDiemBatDau;
  final String? diaDiemKetThuc;
  final double? chieuDai;
  final String? moTa;
  final String? ghiChu;
  final DateTime? createdAt;

  TuyenDuong({
    this.id,
    required this.ten,
    this.loai,
    this.diaDiemBatDau,
    this.diaDiemKetThuc,
    this.chieuDai,
    this.moTa,
    this.ghiChu,
    this.createdAt,
  });

  factory TuyenDuong.fromJson(Map<String, dynamic> json) {
    return TuyenDuong(
      id: json['id'] as int?,
      ten: json['ten'] as String? ?? '',
      loai: json['loai'] as String?,
      diaDiemBatDau: json['dia_diem_bat_dau'] as String?,
      diaDiemKetThuc: json['dia_diem_ket_thuc'] as String?,
      chieuDai: (json['chieu_dai'] as num?)?.toDouble(),
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
        'dia_diem_bat_dau': diaDiemBatDau,
        'dia_diem_ket_thuc': diaDiemKetThuc,
        'chieu_dai': chieuDai,
        'mo_ta': moTa,
        'ghi_chu': ghiChu,
      };
}