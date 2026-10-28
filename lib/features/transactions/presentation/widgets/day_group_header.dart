import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Header row for a day-grouped bucket of transactions.
class DayGroupHeader extends StatelessWidget {
  final DateTime date;
  final int dailyNetVnd;

  const DayGroupHeader({
    super.key,
    required this.date,
    required this.dailyNetVnd,
  });

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final target = DateTime(dt.year, dt.month, dt.day);

    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();

    if (target == today) {
      return 'Hôm nay, $dd/$mm/$yyyy';
    } else if (target == yesterday) {
      return 'Hôm qua, $dd/$mm/$yyyy';
    }

    const weekdays = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final wd = weekdays[dt.weekday];
    return '$wd, $dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    Color netColor = AppColors.textSecondary;
    if (dailyNetVnd > 0) {
      netColor = AppColors.textAccentVerdantPrimary;
    } else if (dailyNetVnd < 0) {
      netColor = AppColors.textAccentRubySecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sp4,
        horizontal: AppSpacing.sp2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDateLabel(date),
            style: VndFormatter.withTabularFigures(
              AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            VndFormatter.format(dailyNetVnd, showSign: dailyNetVnd > 0),
            style: VndFormatter.withTabularFigures(
              AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w600,
                color: netColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
