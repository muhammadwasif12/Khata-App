import 'package:flutter/material.dart';

class KharchaEntity {
  final String id;
  final String businessId;
  final String category;
  final String customCategory;
  final double amount;
  final String note;
  final String paidTo;
  final String vehicleNumber;
  final String driverName;
  final DateTime expenseDate;
  final DateTime createdAt;
  final bool isDeleted;
  final String imagePath;

  static const kharchaCategories = [
    'ڈیزل',
    'خوراک / روٹی',
    'ٹول پلازہ',
    'پولیس',
    'مرمت',
    'لیبر / مزدوری',
    'سروس',
    'منڈوز خرچہ',
    'تنخواہ',
    'ٹوٹل کرایہ',
    'دیگر',
  ];

  static const kharchaCategoryIcons = {
    'ڈیزل': Icons.local_gas_station_outlined,
    'خوراک / روٹی': Icons.restaurant_outlined,
    'ٹول پلازہ': Icons.toll_outlined,
    'پولیس': Icons.local_police_outlined,
    'مرمت': Icons.build_outlined,
    'لیبر / مزدوری': Icons.engineering_outlined,
    'سروس': Icons.miscellaneous_services_outlined,
    'منڈوز خرچہ': Icons.store_outlined,
    'تنخواہ': Icons.payments_outlined,
    'ٹوٹل کرایہ': Icons.directions_car_outlined,
    'دیگر': Icons.more_horiz,
  };

  static const transportCategories = [
    'ڈیزل',
    'ٹول پلازہ',
    'پولیس',
    'مرمت',
    'سروس',
    'ٹوٹل کرایہ',
  ];

  KharchaEntity({
    required this.id,
    required this.businessId,
    required this.category,
    required this.customCategory,
    required this.amount,
    required this.note,
    required this.paidTo,
    required this.vehicleNumber,
    required this.driverName,
    required this.expenseDate,
    required this.createdAt,
    required this.isDeleted,
    this.imagePath = '',
  });
}
