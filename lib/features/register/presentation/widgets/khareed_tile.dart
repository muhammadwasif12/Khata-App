import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/khareed_entity.dart';

class KhareedTile extends StatelessWidget {
  final KhareedEntity item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPdf;

  const KhareedTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('حذف کریں', style: TextStyle(fontFamily: AppTextStyles.urduFont)),
              content: Text('کیا آپ واقعی "${item.itemName}" کا ریکارڈ حذف کرنا چاہتے ہیں؟', style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('نہیں', style: TextStyle(fontFamily: AppTextStyles.urduFont))),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('ہاں', style: TextStyle(fontFamily: AppTextStyles.urduFont, color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) onDelete();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('نام: ${item.itemName}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold))),
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
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF1A6B3C), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'رسید PDF',
                      ),
                    const SizedBox(width: 8),
                    Text('تاریخ: ${DateFormatter.formatDate(item.purchaseDate)}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('گاڑی: ${item.vehicleNumber.isEmpty ? "-" : item.vehicleNumber}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
                    Text('وزن: ${item.weight} ${item.weightUnit}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('کٹوتی: ${item.deduction} ${item.weightUnit}  خالص: ${item.netWeight} ${item.weightUnit}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
                    Text('ریٹ: ${CurrencyFormatter.formatAmount(item.ratePerUnit)}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Divider(height: 20),
                Text('کل رقم: ${CurrencyFormatter.formatAmount(item.totalAmount)}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A6B3C))),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('جمع: ${CurrencyFormatter.formatAmount(item.jama)} 🟢', style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A6B3C))),
                    Text('بقایا: ${CurrencyFormatter.formatAmount(item.baqaya)} 🔴', style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('سابقہ: ${CurrencyFormatter.formatAmount(item.sabhaBaqaya)}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.textSecondary)),
                    Text('خالص بقایا: ${CurrencyFormatter.formatAmount(item.netBaqaya)} 🔴', style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}
