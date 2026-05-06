import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String urduFont = 'NotoNastaliqUrdu';

  static TextStyle display(BuildContext context) => const TextStyle(
    fontFamily: urduFont,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle heading(BuildContext context) => const TextStyle(
    fontFamily: urduFont,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle title(BuildContext context) => const TextStyle(
    fontFamily: urduFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body(BuildContext context) => const TextStyle(
    fontFamily: urduFont,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle caption(BuildContext context) => const TextStyle(
    fontFamily: urduFont,
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle amount = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
}
