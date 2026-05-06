import 'package:hive/hive.dart';

part 'kharcha_model.g.dart';

@HiveType(typeId: 12)
class KharchaModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late String customCategory;

  @HiveField(4)
  late double amount;

  @HiveField(5)
  late String note;

  @HiveField(6)
  late String paidTo;

  @HiveField(7)
  late String vehicleNumber;

  @HiveField(8)
  late String driverName;

  @HiveField(9)
  late DateTime expenseDate;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late bool isDeleted;

  @HiveField(12, defaultValue: '')
  late String imagePath;
}
