import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../constants/app_text_styles.dart';

class PdfOptionsBottomSheet {
  static void show(BuildContext context, File file, {Color? accentColor}) {
    final color = accentColor ?? const Color(0xFF1A6B3C);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'پی ڈی ایف تیار ہے!',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'آپ رپورٹ شیئر یا محفوظ کر سکتے ہیں',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

              // WhatsApp / Share button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.shareXFiles([XFile(file.path)], text: 'رپورٹ');
                  },
                  icon: const Icon(Icons.share_rounded, size: 22),
                  label: const Text(
                    'شیئر کریں (WhatsApp وغیرہ)',
                    style: TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Open / Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    OpenFile.open(file.path);
                  },
                  icon: Icon(Icons.file_open_rounded, size: 22, color: color),
                  label: Text(
                    'پی ڈی ایف دیکھیں / محفوظ کریں',
                    style: TextStyle(
                      fontFamily: AppTextStyles.urduFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
