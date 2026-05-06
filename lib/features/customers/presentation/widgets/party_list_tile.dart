/// Party List Tile Widget
/// Displays a single customer/supplier in a list with name, phone, and balance.
/// Long press shows a dialog (not bottom sheet) for edit/delete actions.
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../customers/domain/entities/party_entity.dart';

class PartyListTile extends StatelessWidget {
  final PartyEntity party;
  final double balance;
  final bool isCredit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PartyListTile({
    super.key,
    required this.party,
    required this.balance,
    required this.isCredit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSettled = balance == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showOptionsDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  party.name.isNotEmpty ? party.name[0] : '?',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (party.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        party.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatAmount(balance.abs()),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSettled
                          ? AppColors.textSecondary
                          : (isCredit ? AppColors.credit : AppColors.debit),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? Colors.grey.shade200
                          : (isCredit ? AppColors.creditBg : AppColors.debitBg),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isSettled
                          ? AppStrings.settled
                          : (isCredit
                              ? AppStrings.lenaHai
                              : AppStrings.denaHai),
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        fontSize: 11,
                        color: isSettled
                            ? AppColors.textSecondary
                            : (isCredit ? AppColors.credit : AppColors.debit),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Party avatar & name header
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  party.name.isNotEmpty ? party.name[0] : '?',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.urduFont,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                party.name,
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (party.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  party.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Edit button
              _DialogOption(
                icon: Icons.edit_outlined,
                iconColor: AppColors.primary,
                label: 'ترمیم کریں',
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              const SizedBox(height: 4),
              // Delete button
              _DialogOption(
                icon: Icons.delete_outline,
                iconColor: AppColors.debit,
                label: 'حذف کریں',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    AppStrings.cancel,
                    style: TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DialogOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDestructive
                ? AppColors.debit.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? AppColors.debit : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? AppColors.debit.withValues(alpha: 0.5)
                    : AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
