import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/farokht_entity.dart';

class FarokhtTile extends StatelessWidget {
  final FarokhtEntity item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPdf;

  const FarokhtTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onPdf,
  });

  String get _statusLabel {
    switch (item.paymentStatus) {
      case 1:
        return 'نقد';
      case 0:
        return 'ادھار';
      case 2:
        return 'جزوی';
      default:
        return '';
    }
  }

  Color get _statusColor {
    switch (item.paymentStatus) {
      case 1:
        return AppColors.credit;
      case 0:
        return AppColors.debit;
      case 2:
        return AppColors.amber;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'حذف کریں',
              style: TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            content: Text(
              'کیا آپ واقعی "${item.itemName}" کا ریکارڈ حذف کرنا چاہتے ہیں؟',
              style: const TextStyle(fontFamily: AppTextStyles.urduFont),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'نہیں',
                  style: TextStyle(fontFamily: AppTextStyles.urduFont),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'ہاں',
                  style: TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) onDelete();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sell_outlined,
                    color: Color(0xFFE67E22),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'چیز: ${item.itemName}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (item.imagePath.isNotEmpty)
                  IconButton(
                    onPressed: () async {
                      try {
                        final result = await OpenFile.open(item.imagePath);
                        if (result.type != ResultType.done && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فائل کھولنے میں ناکامی: ${result.message}', style: const TextStyle(fontFamily: AppTextStyles.urduFont))));
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error opening file')));
                      }
                    },
                    icon: const Icon(Icons.attach_file, color: AppColors.primary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'تصویر دیکھیں',
                  ),
                if (item.imagePath.isNotEmpty)
                  const SizedBox(width: 8),
                if (onPdf != null)
                  IconButton(
                    onPressed: onPdf,
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFFE67E22),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'رسید PDF',
                  ),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.formatDate(item.saleDate),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Buyer + card
            Padding(
              padding: const EdgeInsets.only(right: 46),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'خریدار: ${item.buyerName}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (item.cardNumber.isNotEmpty)
                    Text(
                      'گاڑی: ${item.cardNumber}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Weight + Rate + Total
            Padding(
              padding: const EdgeInsets.only(right: 46),
              child: Row(
                children: [
                  Text(
                    'وزن: ${item.weight.toStringAsFixed(item.weight == item.weight.roundToDouble() ? 0 : 2)} ${item.weightUnit}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ریٹ: ${CurrencyFormatter.formatAmount(item.ratePerUnit)}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'کل: ${CurrencyFormatter.formatAmount(item.totalAmount)}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Credit / Debit row
            Padding(
              padding: const EdgeInsets.only(right: 46),
              child: Row(
                children: [
                  Text(
                    'وصول: ${CurrencyFormatter.formatAmount(item.creditAmount)}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 12,
                      color: AppColors.credit,
                    ),
                  ),
                  const Text(' 🟢 ', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 12),
                  Text(
                    'ادھار: ${CurrencyFormatter.formatAmount(item.debitAmount)}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 12,
                      color: AppColors.debit,
                    ),
                  ),
                  const Text(' 🔴 ', style: TextStyle(fontSize: 10)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
