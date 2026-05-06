/// Cash Entry Tile Widget
/// Displays a single cash entry with amount, type indicator, note, and time.
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../cashbook/domain/entities/cash_entry_entity.dart';

class CashEntryTile extends StatelessWidget {
  final CashEntryEntity entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CashEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCashIn = entry.cashType == CashType.cashIn;
    final color = isCashIn ? AppColors.credit : AppColors.debit;
    final bgColor = isCashIn ? AppColors.creditBg : AppColors.debitBg;
    final icon = isCashIn ? Icons.arrow_downward : Icons.arrow_upward;
    final label = isCashIn ? AppStrings.cashIn : AppStrings.cashOut;
    final prefix = isCashIn ? '+' : '-';

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppColors.primary,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'حذف کریں',
              style: TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            content: const Text(
              'کیا آپ یہ اندراج حذف کرنا چاہتے ہیں؟',
              style: TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  AppStrings.cancel,
                  style: TextStyle(fontFamily: AppTextStyles.urduFont),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  AppStrings.delete,
                  style: TextStyle(
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
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.note.isNotEmpty ? entry.note : label,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Payment method badge / person / attachment
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (entry.paymentMethod.isNotEmpty &&
                            entry.paymentMethod != 'نقد')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amberBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              entry.paymentMethod,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.urduFont,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        if (entry.personName?.isNotEmpty == true)
                          Text(
                            entry.personName!,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (entry.attachmentPath != null)
                          InkWell(
                            onTap: () async {
                              try {
                                final result = await OpenFile.open(
                                  entry.attachmentPath!,
                                );
                                if (result.type != ResultType.done &&
                                    context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'فائل کھولنے میں ناکامی: ${result.message}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error opening file'),
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.attach_file,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDate(entry.entryDate),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$prefix${CurrencyFormatter.formatAmount(entry.amount)}',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
