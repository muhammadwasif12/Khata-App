import 'package:hive/hive.dart';

part 'stock_entry_model.g.dart';

@HiveType(typeId: 5)
class StockEntryModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String productId;

  @HiveField(2)
  late String businessId;

  @HiveField(3)
  late int entryType; // 0 = stockIn (purchase), 1 = stockOut (sale)

  @HiveField(4)
  late double quantity;

  @HiveField(5)
  late double rate; // per unit price

  @HiveField(6)
  late double totalAmount;

  @HiveField(7)
  late String note;

  @HiveField(8)
  late DateTime entryDate;

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  late bool isDeleted;

  StockEntryModel({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.entryType,
    required this.quantity,
    required this.rate,
    required this.totalAmount,
    this.note = '',
    required this.entryDate,
    required this.createdAt,
    this.isDeleted = false,
  });
}
