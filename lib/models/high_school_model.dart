class HighSchool {
  final int? stt;
  final String? maTinhTp;
  final String? tenTinhTp;
  final String? maXaPhuong;
  final String? tenXaPhuong;
  final String? maTruong;
  final String? tenTruong;
  final String? address;
  final String? khuVuc;

  HighSchool({
    this.stt,
    this.maTinhTp,
    this.tenTinhTp,
    this.maXaPhuong,
    this.tenXaPhuong,
    this.maTruong,
    this.tenTruong,
    this.address,
    this.khuVuc,
  });

  factory HighSchool.fromJson(Map<String, dynamic> json) {
    return HighSchool(
      stt: json['stt'] is int ? json['stt'] : int.tryParse('${json['stt']}'),
      maTinhTp: json['ma_tinh_tp']?.toString(),
      tenTinhTp: json['ten_tinh_tp']?.toString(),
      maXaPhuong: json['ma_xa_phuong']?.toString(),
      tenXaPhuong: json['ten_xa_phuong']?.toString(),
      maTruong: json['ma_truong']?.toString(),
      tenTruong: json['ten_truong']?.toString(),
      address: json['dia_chi']?.toString(),
      khuVuc: json['khu_vuc']?.toString(),
    );
  }
}
