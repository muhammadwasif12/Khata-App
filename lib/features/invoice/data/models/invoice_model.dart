import 'package:hive/hive.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 6)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late String invoiceNumber;

  @HiveField(3)
  late String customerName;

  @HiveField(4)
  late String customerPhone;

  @HiveField(5)
  late String? partyId; // linked customer/supplier (optional)

  @HiveField(6)
  late double subtotal;

  @HiveField(7)
  late double discount;

  @HiveField(8)
  late double totalAmount;

  @HiveField(9)
  late double paidAmount;

  @HiveField(10)
  late int status; // 0 = unpaid, 1 = partial, 2 = paid

  @HiveField(11)
  late DateTime invoiceDate;

  @HiveField(12)
  late DateTime createdAt;

  @HiveField(13)
  late bool isDeleted;

  @HiveField(14)
  late String note;

  @HiveField(15)
  late String vehicleNumber;

  InvoiceModel({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    this.customerName = '',
    this.customerPhone = '',
    this.partyId,
    this.subtotal = 0,
    this.discount = 0,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.status = 0,
    required this.invoiceDate,
    required this.createdAt,
    this.isDeleted = false,
    this.note = '',
    this.vehicleNumber = '',
  });
}
