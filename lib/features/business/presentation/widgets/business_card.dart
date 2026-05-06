/// Business Card Widget
/// Displays a single business item in a card format with name, type, owner, and active badge.
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/business_entity.dart';

class BusinessCard extends StatelessWidget {
  final BusinessEntity business;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BusinessCard({
    super.key,
    required this.business,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getTypeIcon() {
    return Icons.store;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActive
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon with type
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: isActive ? Colors.white : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business name
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Type + Currency row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            business.type,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Owner name if available
                    if (business.ownerName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            business.ownerName,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.urduFont,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Active badge + menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.credit,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'فعال',
                        style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'ترمیم',
                              style:
                                  TextStyle(fontFamily: 'NotoNastaliqUrdu'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.debit),
                            SizedBox(width: 8),
                            Text(
                              'حذف کریں',
                              style:
                                  TextStyle(fontFamily: 'NotoNastaliqUrdu'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
