import 'package:hive/hive.dart';

part 'farokht_model.g.dart';

@HiveType(typeId: 11)
class FarokhtModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late String itemName;

  @HiveField(3)
  late String buyerName;

  @HiveField(4)
  late String cardNumber;

  @HiveField(5)
  late double weight;

  @HiveField(6)
  late String weightUnit;

  @HiveField(7)
  late double ratePerUnit;

  @HiveField(8)
  late double totalAmount;

  @HiveField(9)
  late double creditAmount;

  @HiveField(10)
  late double debitAmount;

  @HiveField(11)
  late double tafazul;

  @HiveField(12)
  late int paymentStatus;

  @HiveField(13)
  late String note;

  @HiveField(14)
  late DateTime saleDate;

  @HiveField(15)
  late DateTime createdAt;

  @HiveField(16)
  late bool isDeleted;

  @HiveField(17, defaultValue: '')
  late String customPaymentType;

  @HiveField(18, defaultValue: '')
  late String imagePath;

  FarokhtModel({
    required this.id,
    required this.businessId,
    required this.itemName,
    required this.buyerName,
    this.cardNumber = '',
    required this.weight,
    required this.weightUnit,
    required this.ratePerUnit,
    required this.totalAmount,
    this.creditAmount = 0,
    this.debitAmount = 0,
    this.tafazul = 0,
    required this.paymentStatus,
    this.customPaymentType = '',
    this.note = '',
    required this.saleDate,
    required this.createdAt,
    this.isDeleted = false,
    this.imagePath = '',
  });
}
