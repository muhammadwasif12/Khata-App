import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.isDestructive = true,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.delete,
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'NotoNastaliqUrdu',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'NotoNastaliqUrdu',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppStrings.cancel,
            style: const TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive
                ? AppColors.debit
                : AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontFamily: 'NotoNastaliqUrdu'),
          ),
        ),
      ],
    );
  }
}

/// Convenience function to show a confirmation dialog.
/// Used by screens to confirm destructive actions like delete.
Future<void> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = AppStrings.delete,
  required VoidCallback onConfirm,
  bool isDestructive = true,
}) async {
  final confirmed = await ConfirmationDialog.show(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    isDestructive: isDestructive,
  );
  if (confirmed) {
    onConfirm();
  }
}
