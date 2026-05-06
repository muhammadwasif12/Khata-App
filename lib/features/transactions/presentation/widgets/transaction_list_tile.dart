/// Transaction List Tile Widget
/// Displays a single transaction with amount, type, payment method, note, date, and running balance.
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionListTile extends StatelessWidget {
  final TransactionEntity transaction;
  final double runningBalance;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.runningBalance,
    required this.onTap,
    required this.onDelete,
  });

  /// Payment method icons
  static const Map<String, IconData> _paymentIcons = {
    'نقد': Icons.money,
    'بینک ٹرانسفر': Icons.account_balance,
    'ایزی پیسہ': Icons.phone_android,
    'جاز کیش': Icons.phone_iphone,
    'یوپیسہ': Icons.smartphone,
    'دیگر': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.txnType == TxnType.credit;
    final color = isCredit ? AppColors.debit : AppColors.credit;
    final bgColor = isCredit ? AppColors.debitBg : AppColors.creditBg;
    final label = isCredit ? AppStrings.gave : AppStrings.received;
    final prefix = isCredit ? '-' : '+';
    final pmIcon = _paymentIcons[transaction.paymentMethod] ?? Icons.payment;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppColors.debit,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppStrings.deleteTransaction,
              style: const TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            content: Text(
              AppStrings.deleteTxnMsg,
              style: const TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppStrings.cancel,
                  style: const TextStyle(fontFamily: AppTextStyles.urduFont),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppStrings.delete,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: AppColors.debit,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '$prefix${CurrencyFormatter.formatAmount(transaction.amount)}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Payment method badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(pmIcon, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                transaction.paymentMethod,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.urduFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (transaction.attachmentPath != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () async {
                                try {
                                  final result = await OpenFile.open(transaction.attachmentPath!);
                                  if (result.type != ResultType.done && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('فائل کھولنے میں ناکامی: ${result.message}')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error opening file')),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.attach_file,
                                    size: 20, color: AppColors.primary),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (transaction.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          transaction.note,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.formatDate(transaction.txnDate),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.urduFont,
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${AppStrings.runningBalance}: ',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatAmount(runningBalance.abs()),
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: runningBalance >= 0
                                    ? AppColors.credit
                                    : AppColors.debit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
