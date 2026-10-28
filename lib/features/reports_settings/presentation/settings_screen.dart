import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import 'providers/reports_settings_providers.dart';

/// Secondary Screen: Settings & Encrypted Backup/Restore (`Cài đặt & Sao lưu`).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _bufferCtrl = TextEditingController();
  bool _permissionDeniedBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scheduler = ref.read(notificationSchedulerProvider);
      if (!scheduler.isPermissionGranted) {
        setState(() => _permissionDeniedBanner = true);
      }
    });
  }

  @override
  void dispose() {
    _bufferCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Sao lưu'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Lỗi tải cài đặt: $err'),
        ),
        data: (setting) {
          final currentBufferVnd = setting.minimumCashBufferVnd;
          final currentPeriodDay = setting.periodStartDay;
          final notificationsEnabled = setting.notificationsEnabled;

          return SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_permissionDeniedBanner) _buildPermissionBanner(),
                _buildFinancialRulesCard(
                  context: context,
                  currentBufferVnd: currentBufferVnd,
                  currentPeriodDay: currentPeriodDay,
                  notificationsEnabled: notificationsEnabled,
                ),
                AppSpacing.gapH16,
                _buildBackupExportCard(context),
                AppSpacing.gapH16,
                _buildDataToolsCard(context),
                const SizedBox(height: AppSpacing.sp10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAccentMarigoldSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_paused_outlined,
              color: AppColors.textAccentMarigoldPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quyền thông báo đang tắt trên thiết bị. Nhắc nhở hóa đơn vẫn hiển thị trong ứng dụng.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textAccentMarigoldPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRulesCard({
    required BuildContext context,
    required int currentBufferVnd,
    required int currentPeriodDay,
    required bool notificationsEnabled,
  }) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thiết lập tài chính & Nhắc nhở',
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khoản đệm tiền mặt tối thiểu',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      VndFormatter.format(currentBufferVnd),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textAccentVerdantPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                identifier: 'input_cash_buffer',
                button: true,
                child: OutlinedButton(
                  onPressed: () =>
                      _showEditBufferDialog(context, currentBufferVnd),
                  child: const Text('Cập nhật'),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderSecondary),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày bắt đầu chu kỳ tháng',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Ngày $currentPeriodDay hàng tháng',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                identifier: 'input_period_start_day',
                child: DropdownButton<int>(
                  value: currentPeriodDay.clamp(1, 28),
                  items: List.generate(
                    28,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        'Ngày ${i + 1}',
                        style: AppTypography.body.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(reportsSettingsControllerProvider.notifier)
                          .updatePeriodStartDay(val);
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderSecondary),
          Semantics(
            identifier: 'toggle_notifications',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Nhắc nhở hóa đơn & thu nhập',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Lên lịch nhắc lúc 20:00 tối (100% ngoại tuyến)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              value: notificationsEnabled,
              onChanged: (enabled) async {
                await ref
                    .read(reportsSettingsControllerProvider.notifier)
                    .updateNotificationsEnabled(enabled);
                if (enabled) {
                  final scheduler = ref.read(notificationSchedulerProvider);
                  final granted = await scheduler.initialize();
                  if (mounted) {
                    setState(() {
                      _permissionDeniedBanner = !granted;
                    });
                  }
                }
              },
            ),
          ),
          AppSpacing.gapH8,
          Semantics(
            identifier: 'btn_test_notification',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notification_important_outlined),
                label: const Text('Gửi thông báo kiểm tra ngay'),
                onPressed: () async {
                  final scheduler = ref.read(notificationSchedulerProvider);
                  final granted = await scheduler.initialize();
                  if (mounted) {
                    setState(() {
                      _permissionDeniedBanner = !granted;
                    });
                  }
                  if (granted) {
                    await scheduler.showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Đã gửi thông báo kiểm tra thành công!'),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.surfaceAccentRubyPrimary,
                          content: Text(
                            'Không thể gửi: Quyền thông báo bị từ chối trên thiết bị.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupExportCard(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sao lưu bảo mật & Xuất dữ liệu',
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã hóa PBKDF2-HMAC-SHA256 (120.000 vòng) & AES-256-GCM',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapH12,
          Semantics(
            identifier: 'btn_export_csv',
            button: true,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Xuất giao dịch ra CSV'),
              onPressed: () => _handleExportCsv(context),
            ),
          ),
          AppSpacing.gapH8,
          Semantics(
            identifier: 'btn_encrypted_backup',
            button: true,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_outline),
              label: const Text('Tạo bản sao lưu mã hóa (.json)'),
              onPressed: () => _showEncryptedBackupDialog(context),
            ),
          ),
          AppSpacing.gapH8,
          Semantics(
            identifier: 'btn_encrypted_restore',
            button: true,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Khôi phục từ bản sao lưu mã hóa'),
              onPressed: () => _showEncryptedRestoreDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataToolsCard(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Công cụ dữ liệu',
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH12,
          Semantics(
            identifier: 'btn_generate_sample_data',
            button: true,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.auto_graph_outlined),
              label: const Text('Tạo dữ liệu mẫu'),
              onPressed: () async {
                await ref
                    .read(reportsSettingsControllerProvider.notifier)
                    .generateSampleData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã tạo dữ liệu mẫu thành công!'),
                    ),
                  );
                }
              },
            ),
          ),
          AppSpacing.gapH8,
          Semantics(
            identifier: 'btn_reset_database',
            button: true,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textAccentRubyPrimary,
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Đặt lại toàn bộ dữ liệu về 0 ₫'),
              onPressed: () => _showResetConfirmationDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBufferDialog(
    BuildContext context,
    int currentBufferVnd,
  ) async {
    _bufferCtrl.text = currentBufferVnd.toString();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khoản đệm tiền mặt tối thiểu'),
        content: TextField(
          controller: _bufferCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số tiền VND (ví dụ: 500000)',
            suffixText: '₫',
          ),
          style: AppTypography.body.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final parsed =
                  VndFormatter.tryParse(_bufferCtrl.text.trim()) ?? 0;
              await ref
                  .read(reportsSettingsControllerProvider.notifier)
                  .updateMinimumCashBuffer(parsed < 0 ? 0 : parsed);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportCsv(BuildContext context) async {
    final csv =
        await ref.read(reportsSettingsControllerProvider.notifier).exportCsv();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dữ liệu CSV đã sẵn sàng'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: AppTypography.caption.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEncryptedBackupDialog(BuildContext context) async {
    final passCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mật khẩu sao lưu mã hóa'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nhập mật khẩu bảo vệ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pwd = passCtrl.text;
              if (pwd.isEmpty) return;
              Navigator.of(ctx).pop();
              final jsonOut = await ref
                  .read(reportsSettingsControllerProvider.notifier)
                  .exportEncryptedBackup(pwd);
              if (!context.mounted) return;
              await showDialog<void>(
                context: context,
                builder: (resCtx) => AlertDialog(
                  title: const Text('Bản sao lưu DONGTIEN_ENC_V1'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        jsonOut,
                        style: AppTypography.caption.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(resCtx).pop(),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Mã hóa & Xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEncryptedRestoreDialog(BuildContext context) async {
    final jsonCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục bản sao lưu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jsonCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nội dung JSON sao lưu (DONGTIEN_ENC_V1)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu giải mã',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final res = await ref
                    .read(reportsSettingsControllerProvider.notifier)
                    .restoreEncryptedBackup(
                      jsonContent: jsonCtrl.text.trim(),
                      password: passCtrl.text,
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã khôi phục ${res.transactionsCount} giao dịch & ${res.accountsCount} tài khoản!',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceAccentRubyPrimary,
                      content: Text('Khôi phục thất bại: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Giải mã & Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetConfirmationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đặt lại dữ liệu'),
        content: const Text(
          'Toàn bộ giao dịch, quỹ tiền và kế hoạch sẽ được đặt lại về trạng thái mặc định ban đầu (0 ₫).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceAccentRubyPrimary,
            ),
            onPressed: () async {
              await ref
                  .read(reportsSettingsControllerProvider.notifier)
                  .resetDatabaseToZero();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đặt lại dữ liệu về 0 ₫ thành công.'),
                  ),
                );
              }
            },
            child: const Text('Đặt lại về 0 ₫'),
          ),
        ],
      ),
    );
  }
}
