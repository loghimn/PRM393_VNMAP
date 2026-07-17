import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Hiển thị popup thông báo đẹp mắt với animation nâng cao
class PopupNotification {
  /// Hiển thị dialog thông báo thành công
  /// [autoCloseDuration] nếu != null sẽ tự động đóng sau khoảng thời gian
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
    Duration? autoCloseDuration,
  }) {
    final result = showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(100),
      builder: (ctx) => PopupBase(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF22C55E),
        gradientColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
        title: title,
        message: message,
        buttonText: buttonText ?? 'Đã hiểu',
        onPressed: () {
          Navigator.pop(ctx);
          onDismiss?.call();
        },
        autoCloseDuration: autoCloseDuration,
      ),
    );
    // Auto close if duration specified
    if (autoCloseDuration != null && context.mounted) {
      Future.delayed(autoCloseDuration, () {
        // Try to dismiss the dialog
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
    return result;
  }

  /// Hiển thị dialog thông báo lỗi
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
    Duration? autoCloseDuration,
  }) {
    final result = showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(100),
      builder: (ctx) => PopupBase(
        icon: Icons.error_rounded,
        iconColor: const Color(0xFFEF4444),
        gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        title: title,
        message: message,
        buttonText: buttonText ?? 'Đã hiểu',
        onPressed: () {
          Navigator.pop(ctx);
          onDismiss?.call();
        },
        autoCloseDuration: autoCloseDuration,
      ),
    );
    if (autoCloseDuration != null && context.mounted) {
      Future.delayed(autoCloseDuration, () {
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
    return result;
  }

  /// Hiển thị dialog thông báo cảnh báo / thông tin
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
    IconData? icon,
    Duration? autoCloseDuration,
  }) {
    final result = showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(100),
      builder: (ctx) => PopupBase(
        icon: icon ?? Icons.info_rounded,
        iconColor: const Color(0xFF3B82F6),
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        title: title,
        message: message,
        buttonText: buttonText ?? 'Đã hiểu',
        onPressed: () {
          Navigator.pop(ctx);
          onDismiss?.call();
        },
        autoCloseDuration: autoCloseDuration,
      ),
    );
    if (autoCloseDuration != null && context.mounted) {
      Future.delayed(autoCloseDuration, () {
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
    return result;
  }

  /// Hiển thị dialog xác nhận (có nút Hủy / Đồng ý)
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(100),
      builder: (ctx) => PopupBase.confirm(
        icon: Icons.help_outline_rounded,
        iconColor: const Color(0xFFF59E0B),
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        title: title,
        message: message,
        confirmText: confirmText ?? 'Đồng ý',
        cancelText: cancelText ?? 'Hủy',
        confirmColor: confirmColor,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
  }

  /// Hiển thị loading popup khi đang xử lý / gửi yêu cầu
  static void showLoading({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(100),
      builder: (ctx) => PopupBase.loading(title: title, message: message),
    );
  }

  /// Hiển thị popup thông tin yêu cầu đang chờ duyệt
  /// Cho phép người dùng xem chi tiết hoặc quay lại
  static Future<void> showPendingInfo({
    required BuildContext context,
    required String title,
    required String message,
    required String headName,
    required String address,
    required String statusText,
    required Color statusColor,
    required VoidCallback onViewDetail,
    required VoidCallback onBack,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(100),
      builder: (ctx) => PopupBase.pendingInfo(
        title: title,
        message: message,
        headName: headName,
        address: address,
        statusText: statusText,
        statusColor: statusColor,
        onViewDetail: onViewDetail,
        onBack: onBack,
      ),
    );
  }
}

/// Base popup widget với animation và styling
class PopupBase extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;
  final Duration? autoCloseDuration;

  // For confirmation dialog
  final bool isConfirm;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  // For loading
  final bool isLoading;

  // For pending info
  final bool isPendingInfo;
  final String? headName;
  final String? address;
  final String? statusText;
  final Color? statusColor;
  final VoidCallback? onViewDetail;
  final VoidCallback? onBack;

  const PopupBase({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
    this.isConfirm = false,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
    this.isLoading = false,
    this.isPendingInfo = false,
    this.headName,
    this.address,
    this.statusText,
    this.statusColor,
    this.onViewDetail,
    this.onBack,
    this.autoCloseDuration,
  });

  const PopupBase.confirm({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
    this.isConfirm = true,
    this.buttonText,
    this.onPressed,
    this.isLoading = false,
    this.isPendingInfo = false,
    this.headName,
    this.address,
    this.statusText,
    this.statusColor,
    this.onViewDetail,
    this.onBack,
    this.autoCloseDuration,
  });

  const PopupBase.loading({
    super.key,
    required this.title,
    required this.message,
    this.isLoading = true,
    this.icon = Icons.info_rounded,
    this.iconColor = AppColors.primary,
    this.gradientColors = const [Color(0xFF3B82F6), Color(0xFF2563EB)],
    this.buttonText,
    this.onPressed,
    this.isConfirm = false,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
    this.isPendingInfo = false,
    this.headName,
    this.address,
    this.statusText,
    this.statusColor,
    this.onViewDetail,
    this.onBack,
    this.autoCloseDuration,
  });

  const PopupBase.pendingInfo({
    super.key,
    required this.title,
    required this.message,
    required this.headName,
    required this.address,
    required this.statusText,
    required this.statusColor,
    required this.onViewDetail,
    required this.onBack,
    this.isPendingInfo = true,
    this.isLoading = false,
    this.icon = Icons.info_rounded,
    this.iconColor = AppColors.primary,
    this.gradientColors = const [Color(0xFFF59E0B), Color(0xFFD97706)],
    this.buttonText,
    this.onPressed,
    this.isConfirm = false,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
    this.autoCloseDuration,
  });

  @override
  State<PopupBase> createState() => _PopupBaseState();
}

class _PopupBaseState extends State<PopupBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const ElasticOutCurve(0.8),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 32,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    _buildLoadingHeader()
                  else if (widget.isPendingInfo)
                    _buildPendingInfoHeader()
                  else
                    _buildDefaultHeader(),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Pulse animation container
          _PulseAnimation(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color(0xFFF59E0B),
            Color(0xFFD97706),
            Color(0xFFB45309),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          if (widget.isPendingInfo) ...[
            _buildPendingInfoContent(),
          ] else ...[
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!widget.isConfirm && !widget.isLoading && !widget.isPendingInfo)
            _buildButton(
              text: widget.buttonText!,
              color: widget.gradientColors.first,
              onPressed: widget.onPressed!,
            )
          else if (widget.isPendingInfo)
            _buildPendingInfoButtons()
          else if (widget.isConfirm) ...[
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: widget.cancelText!,
                    color: AppColors.textSecondary,
                    onPressed: widget.onCancel!,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    text: widget.confirmText!,
                    color: widget.confirmColor ?? widget.gradientColors.first,
                    onPressed: widget.onConfirm!,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingInfoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.searchBg.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chủ hộ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.headName ?? 'N/A',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (widget.statusColor ?? AppColors.warning).withAlpha(
                    20,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.statusText ?? 'Chờ duyệt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.statusColor ?? AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.address ?? 'Chưa có địa chỉ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pending message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yêu cầu của bạn đang được xem xét',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInfoButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            text: 'Quay lại',
            color: AppColors.textSecondary,
            onPressed: widget.onBack!,
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildButton(
            text: 'Xem chi tiết',
            color: AppColors.warning,
            onPressed: widget.onViewDetail!,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 48,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withAlpha(80)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
    );
  }
}

/// Widget tạo hiệu ứng pulse cho loading spinner
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnim.value, child: child);
      },
      child: widget.child,
    );
  }
}
