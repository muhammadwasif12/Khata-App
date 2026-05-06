import 'package:hive/hive.dart';

part 'invoice_item_model.g.dart';

@HiveType(typeId: 7)
class InvoiceItemModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String invoiceId;

  @HiveField(2)
  late String productName;

  @HiveField(3)
  late String? productId; // linked product (optional)

  @HiveField(4)
  late double quantity;

  @HiveField(5)
  late double rate;

  @HiveField(6)
  late double amount;

  @HiveField(7)
  late String unit;

  InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productName,
    this.productId,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.unit = 'عدد',
  });
}
