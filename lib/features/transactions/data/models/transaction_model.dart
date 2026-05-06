import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String partyId;

  @HiveField(2)
  late String businessId;

  @HiveField(3)
  late int txnType;

  @HiveField(4)
  late double amount;

  @HiveField(5)
  late String note;

  @HiveField(6)
  late DateTime txnDate;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late bool isDeleted;

  @HiveField(9)
  late String paymentMethod;

  @HiveField(10)
  String? attachmentPath;

  @HiveField(11)
  String? attachmentType;

  TransactionModel({
    required this.id,
    required this.partyId,
    required this.businessId,
    required this.txnType,
    required this.amount,
    this.note = '',
    required this.txnDate,
    required this.createdAt,
    this.isDeleted = false,
    this.paymentMethod = 'نقد',
    this.attachmentPath,
    this.attachmentType,
  });
}
