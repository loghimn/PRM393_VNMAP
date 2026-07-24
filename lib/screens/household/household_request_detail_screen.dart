import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/household_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_request_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/popup_notification.dart';

class HouseholdRequestDetailScreen extends StatefulWidget {
  final int requestId;
  final DatabaseService? databaseService;

  const HouseholdRequestDetailScreen({
    super.key,
    required this.requestId,
    this.databaseService,
  });

  @override
  State<HouseholdRequestDetailScreen> createState() =>
      _HouseholdRequestDetailScreenState();
}

class _HouseholdRequestDetailScreenState
    extends State<HouseholdRequestDetailScreen> {
  late final _db = widget.databaseService ?? DatabaseService();
  HouseholdRequest? _request;
  bool _isLoading = true;
  bool _isProcessing = false;
  final _adminNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() => _isLoading = true);
    try {
      final request = await _db.fetchHouseholdRequestById(widget.requestId);
      if (mounted) {
        setState(() {
          _request = request;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _adminNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final auth = context.read<AuthProvider>();
    final adminId = auth.currentUser?.id;
    if (adminId == null) return;

    setState(() => _isProcessing = true);
    final provider = context.read<HouseholdRequestProvider>();
    final ok = await provider.approveRequest(
      widget.requestId,
      approvedBy: adminId,
      adminNote: _adminNoteCtrl.text.trim().isNotEmpty
          ? _adminNoteCtrl.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (ok) {
        PopupNotification.showSuccess(
          context: context,
          title: 'Phê duyệt thành công!',
          message: 'Yêu cầu tạo hộ gia đình đã được phê duyệt.',
          autoCloseDuration: const Duration(seconds: 3),
        );
        await _loadRequest();
      } else {
        PopupNotification.showError(
          context: context,
          title: 'Phê duyệt thất bại',
          message: provider.error ?? 'Lỗi không xác định',
        );
      }
    }
  }

  Future<void> _reject() async {
    final auth = context.read<AuthProvider>();
    final adminId = auth.currentUser?.id;
    if (adminId == null) return;

    setState(() => _isProcessing = true);
    final provider = context.read<HouseholdRequestProvider>();
    final ok = await provider.rejectRequest(
      widget.requestId,
      approvedBy: adminId,
      adminNote: _adminNoteCtrl.text.trim().isNotEmpty
          ? _adminNoteCtrl.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (ok) {
        PopupNotification.showSuccess(
          context: context,
          title: 'Đã từ chối yêu cầu',
          message: 'Yêu cầu tạo hộ gia đình đã bị từ chối.',
          autoCloseDuration: const Duration(seconds: 3),
        );
        await _loadRequest();
      } else {
        PopupNotification.showError(
          context: context,
          title: 'Từ chối thất bại',
          message: provider.error ?? 'Lỗi không xác định',
        );
      }
    }
  }

  void _showImagePreview(List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ImagePreviewScreen(images: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == 'admin';
    final isPending = _request?.status == 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết yêu cầu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
          ? const Center(child: Text('Không tìm thấy yêu cầu'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor().withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(_statusIcon(), color: _statusColor(), size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusText(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(),
                              ),
                            ),
                            if (_request!.createdAt != null)
                              Text(
                                'Tạo lúc: ${_request!.createdAt.toString().substring(0, 16)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Personal info
                  _buildSection('Thông tin chủ hộ', [
                    _buildInfoRow('Họ tên', _request!.headOfHousehold),
                    _buildInfoRow('Số điện thoại', _request!.phone),
                    _buildInfoRow('Email', _request!.email),
                    if (_request!.population != null)
                      _buildInfoRow(
                        'Số nhân khẩu',
                        _request!.population.toString(),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  // Address info
                  _buildSection('Địa chỉ', [
                    _buildInfoRow('Số nhà', _request!.houseNumber),
                    _buildInfoRow('Đường', _request!.street),
                    _buildInfoRow('Tổ', _request!.neighborhood),
                    _buildInfoRow('Phường/Xã', _request!.ward),
                    _buildInfoRow('Quận/Huyện', _request!.district),
                    _buildInfoRow('Tỉnh/Thành phố', _request!.city),
                  ]),
                  const SizedBox(height: 16),
                  // Images
                  if (_request!.imageUrls.isNotEmpty)
                    _buildSection('Hình ảnh', [
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _request!.imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GestureDetector(
                                onTap: () => _showImagePreview(
                                  _request!.imageUrls,
                                  index,
                                ),
                                child: Image.network(
                                  _request!.imageUrls[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[100],
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            value:
                                                progress.expectedTotalBytes !=
                                                    null
                                                ? progress.cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  const SizedBox(height: 16),
                  // Notes
                  if (_request!.notes != null && _request!.notes!.isNotEmpty)
                    _buildSection('Ghi chú', [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _request!.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ]),
                  const SizedBox(height: 16),
                  // Admin note (if already processed)
                  if (_request!.adminNote != null &&
                      _request!.adminNote!.isNotEmpty)
                    _buildSection('Ghi chú của admin', [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _request!.adminNote!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ]),
                  // Admin actions (only for pending requests)
                  if (isAdmin && isPending) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Phản hồi của admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _adminNoteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập ghi chú (nếu có)...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.searchBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.border.withAlpha(80),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.border.withAlpha(80),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing ? null : _reject,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.error,
                              ),
                              label: Text(
                                'Từ chối',
                                style: TextStyle(color: AppColors.error),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _approve,
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                'Phê duyệt',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor() {
    switch (_request!.status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon() {
    switch (_request!.status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _statusText() {
    switch (_request!.status) {
      case 'pending':
        return 'Chờ phê duyệt';
      case 'approved':
        return 'Đã phê duyệt';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }
}

// Image preview screen
class _ImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreviewScreen({required this.images, required this.initialIndex});

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
