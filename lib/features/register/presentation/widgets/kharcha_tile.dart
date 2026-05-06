import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/kharcha_entity.dart';

class KharchaTile extends StatelessWidget {
  final KharchaEntity item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPdf;

  const KharchaTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final catName = item.category == 'دیگر' && item.customCategory.isNotEmpty ? item.customCategory : item.category;
    final iconData = KharchaEntity.kharchaCategoryIcons[item.category] ?? Icons.money_off;

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
              content: Text('کیا آپ واقعی اس خرچے کو حذف کرنا چاہتے ہیں؟', style: const TextStyle(fontFamily: AppTextStyles.urduFont)),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFC0392B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(iconData, color: const Color(0xFFC0392B), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(catName, style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 16, fontWeight: FontWeight.bold))),
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
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFC0392B), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'رسید PDF',
                            ),
                          const SizedBox(width: 6),
                          Text('${CurrencyFormatter.formatAmount(item.amount)} 🔴', style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                        ],
                      ),
                      if (item.vehicleNumber.isNotEmpty || item.driverName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('گاڑی: ${item.vehicleNumber.isEmpty ? "-" : item.vehicleNumber}   ڈرائیور: ${item.driverName.isEmpty ? "-" : item.driverName}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
                      ],
                      if (item.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('نوٹ: ${item.note}', style: const TextStyle(fontFamily: AppTextStyles.urduFont, fontSize: 13, color: AppColors.textSecondary)),
                      ],
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
