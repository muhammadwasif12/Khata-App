import 'package:hive/hive.dart';

part 'cash_entry_model.g.dart';

@HiveType(typeId: 3)
class CashEntryModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late int cashType;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late String note;

  @HiveField(5)
  late DateTime entryDate;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late bool isDeleted;

  @HiveField(8)
  late String paymentMethod;

  @HiveField(9)
  String? personName;

  @HiveField(10)
  String? accountTitle;

  @HiveField(11)
  String? attachmentPath;

  @HiveField(12)
  String? attachmentType;

  CashEntryModel({
    required this.id,
    required this.businessId,
    required this.cashType,
    required this.amount,
    this.note = '',
    required this.entryDate,
    required this.createdAt,
    this.isDeleted = false,
    this.paymentMethod = 'نقد',
    this.personName,
    this.accountTitle,
    this.attachmentPath,
    this.attachmentType,
  });
}
