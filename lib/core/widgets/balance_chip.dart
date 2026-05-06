import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';

class BalanceChip extends StatelessWidget {
  final double amount;
  final bool isCredit;

  const BalanceChip({super.key, required this.amount, required this.isCredit});

  @override
  Widget build(BuildContext context) {
    if (amount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'بے باق',
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final color = isCredit ? AppColors.credit : AppColors.debit;
    final bgColor = isCredit ? AppColors.creditBg : AppColors.debitBg;
    final label = isCredit ? 'لینا ہے' : 'دینا ہے';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            CurrencyFormatter.formatAmount(amount.abs()),
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
