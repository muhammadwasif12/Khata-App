import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 4)
class ProductModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String unit; // kg, pcs, dozen, meter, litre, etc.

  @HiveField(4)
  late double purchasePrice;

  @HiveField(5)
  late double salePrice;

  @HiveField(6)
  late double currentStock;

  @HiveField(7)
  late double lowStockAlert; // alert when stock falls below

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late bool isDeleted;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.unit = 'عدد',
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.currentStock = 0,
    this.lowStockAlert = 5,
    required this.createdAt,
    this.isDeleted = false,
  });
}
