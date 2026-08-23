import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../models/dashboard.dart';

class SalesBarChart extends StatelessWidget {
  const SalesBarChart({
    super.key,
    required this.buckets,
    required this.period,
  });

  final List<SalesBucket> buckets;
  final DashboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (buckets.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.gray900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLight ? AppColors.gray200 : AppColors.gray800,
            width: 1.2,
          ),
        ),
        child: Text(
          'No sales in this period',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isLight ? AppColors.gray500 : AppColors.gray400,
          ),
        ),
      );
    }

    final maxRev = buckets.fold<int>(
      0,
      (m, b) => b.revenue > m ? b.revenue : m,
    );
    final scale = maxRev <= 0 ? 1.0 : maxRev.toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.gray900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? AppColors.gray200 : AppColors.gray800,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Sales trend', style: theme.textTheme.titleLarge),
              const Spacer(),
              if (maxRev > 0)
                Text(
                  'Peak ${formatDASimple(maxRev)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLight ? AppColors.gray500 : AppColors.gray400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((b) {
                final h = b.revenue <= 0
                    ? 4.0
                    : (b.revenue / scale * 110).clamp(4.0, 110.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (b.revenue > 0 && buckets.length <= 12)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              b.count > 0 ? '${b.count}' : '',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isLight
                                    ? AppColors.gray500
                                    : AppColors.gray400,
                              ),
                            ),
                          ),
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            color:
                                isLight ? AppColors.primary : AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatLabel(b.label, period),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color:
                                isLight ? AppColors.gray500 : AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String label, DashboardPeriod period) {
    if (period == DashboardPeriod.today && label.length <= 2) {
      return '$label:00';
    }
    if (period == DashboardPeriod.month || period == DashboardPeriod.custom) {
      return label.length <= 2 ? label : label;
    }
    return label.length > 3 ? label.substring(0, 3) : label;
  }
}
