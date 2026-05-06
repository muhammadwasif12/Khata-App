/// Daily Summary Card Widget
/// Shows today's cash in, cash out, and closing balance.
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

class DailySummaryCard extends StatelessWidget {
  final double cashIn;
  final double cashOut;
  final String dateLabel;

  const DailySummaryCard({
    super.key,
    required this.cashIn,
    required this.cashOut,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final closingBalance = cashIn - cashOut;
    final isPositive = closingBalance >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            dateLabel,
            style: const TextStyle(
              fontFamily: AppTextStyles.urduFont,
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: AppStrings.todayCashIn,
                  amount: cashIn,
                  color: Colors.white,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _SummaryItem(
                  label: AppStrings.todayCashOut,
                  amount: cashOut,
                  color: Colors.white,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.closingCash,
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : '-'}${CurrencyFormatter.formatAmount(closingBalance.abs())}',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.greenAccent.shade100 : Colors.redAccent.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 12,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.formatAmount(amount),
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
