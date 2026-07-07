import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/khu_pho_model.dart';
import '../../providers/dai_dien_provider.dart';
import '../../models/dai_dien_model.dart';
import '../dai_dien/dai_dien_form_screen.dart';
import '../dai_dien/dai_dien_detail_screen.dart';
import 'khu_pho_form_screen.dart';

class KhuPhoDetailScreen extends StatefulWidget {
  final KhuPhoModel khuPho;

  const KhuPhoDetailScreen({super.key, required this.khuPho});

  @override
  State<KhuPhoDetailScreen> createState() => _KhuPhoDetailScreenState();
}

class _KhuPhoDetailScreenState extends State<KhuPhoDetailScreen> {
  late KhuPhoModel _khuPho;
  List<DaiDienModel> _daiDiens = [];
  bool _loadingDaiDiens = false;

  @override
  void initState() {
    super.initState();
    _khuPho = widget.khuPho;
    _loadDaiDiens();
  }

  Future<void> _loadDaiDiens() async {
    if (_khuPho.id == null) return;
    setState(() => _loadingDaiDiens = true);
    try {
      final provider = context.read<DaiDienProvider>();
      // Load all and filter locally
      if (provider.danhSach.isEmpty) {
        await provider.loadData();
      }
      setState(() {
        _daiDiens = provider.danhSach.where((d) => d.khuPhoId == _khuPho.id).toList();
      });
    } catch (e) {
      print('Error loading dai diens: $e');
    } finally {
      setState(() => _loadingDaiDiens = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(
        title: Text(_khuPho.tenKhuPho),
        backgroundColor: const Color(0xff1e293b),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KhuPhoFormScreen(khuPho: _khuPho),
                ),
              );
              if (result != null && result is KhuPhoModel) {
                setState(() => _khuPho = result);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin khu phố
            Card(
              color: const Color(0xff1e293b),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin khu phố',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Tên khu phố', _khuPho.tenKhuPho),
                    _buildInfoRow('Địa chỉ', _khuPho.diaChi ?? 'Chưa có'),
                    _buildInfoRow('Mô tả', _khuPho.moTa ?? 'Chưa có'),
                    if (_khuPho.createdAt != null)
                      _buildInfoRow(
                        'Ngày tạo',
                        '${_khuPho.createdAt!.day}/${_khuPho.createdAt!.month}/${_khuPho.createdAt!.year}',
                      ),
                    if (_khuPho.updatedAt != null)
                      _buildInfoRow(
                        'Cập nhật',
                        '${_khuPho.updatedAt!.day}/${_khuPho.updatedAt!.month}/${_khuPho.updatedAt!.year}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách đại diện
            Card(
              color: const Color(0xff1e293b),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đại diện khu phố',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DaiDienFormScreen(
                                  khuPhoId: _khuPho.id,
                                ),
                              ),
                            ).then((_) => _loadDaiDiens());
                          },
                          icon: const Icon(Icons.add, color: Colors.green),
                          label: const Text(
                            'Thêm đại diện',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadingDaiDiens)
                      const Center(child: CircularProgressIndicator())
                    else if (_daiDiens.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Chưa có đại diện nào',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ..._daiDiens.map((d) => _buildDaiDienItem(d)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaiDienItem(DaiDienModel d) {
    return Card(
      color: const Color(0xff334155),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          d.hoTen,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          d.soDienThoai ?? 'Chưa có SĐT',
          style: const TextStyle(color: Colors.white54),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DaiDienDetailScreen(daiDien: d),
            ),
          );
        },
      ),
    );
  }
}