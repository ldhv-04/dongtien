import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Tile displaying a chronological movement inside an Envelope Detail screen.
class MovementHistoryTile extends StatelessWidget {
  final EnvelopeMovement movement;
  final int currentEnvelopeId;
  final Map<int, String> envelopeNames;

  const MovementHistoryTile({
    super.key,
    required this.movement,
    required this.currentEnvelopeId,
    required this.envelopeNames,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInflow = movement.destEnvelopeId == currentEnvelopeId;
    final dt = DateTime.fromMillisecondsSinceEpoch(movement.occurredAt);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    String title;
    IconData icon;
    Color iconColor;

    switch (movement.movementType) {
      case 'ALLOCATE':
        title = 'Phân bổ từ tiền khả dụng';
        icon = Icons.arrow_downward_rounded;
        iconColor = AppColors.iconAccentVerdant;
        break;
      case 'RELEASE':
        title = 'Giải phóng về tiền khả dụng';
        icon = Icons.arrow_upward_rounded;
        iconColor = AppColors.iconAccentEmber;
        break;
      case 'TRANSFER':
        if (isInflow) {
          final srcName =
              envelopeNames[movement.sourceEnvelopeId] ?? 'quỹ khác';
          title = 'Nhận chuyển quỹ từ $srcName';
        } else {
          final dstName = envelopeNames[movement.destEnvelopeId] ?? 'quỹ khác';
          title = 'Chuyển sang quỹ $dstName';
        }
        icon = Icons.sync_alt_rounded;
        iconColor = AppColors.iconAccentSandstone;
        break;
      case 'SPEND':
        title = 'Chi tiêu từ quỹ';
        icon = Icons.shopping_bag_outlined;
        iconColor = AppColors.iconAccentRuby;
        break;
      case 'REFUND_RESTORE':
        title = 'Hoàn tiền khôi phục quỹ';
        icon = Icons.replay_rounded;
        iconColor = AppColors.iconAccentVerdant;
        break;
      default:
        title = 'Đảo ngược giao dịch (Reversal)';
        icon = Icons.undo_rounded;
        iconColor = AppColors.iconSecondary;
    }

    final signedAmount = isInflow ? movement.amountVnd : -movement.amountVnd;

    return Semantics(
      identifier: 'item_movement_${movement.id}',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp5),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: VndFormatter.withTabularFigures(
                      AppTypography.caption,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              VndFormatter.format(signedAmount, showSign: isInflow),
              style: VndFormatter.withTabularFigures(
                AppTypography.bodyMedium.copyWith(
                  color: isInflow
                      ? AppColors.textAccentVerdantPrimary
                      : AppColors.textAccentRubySecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
