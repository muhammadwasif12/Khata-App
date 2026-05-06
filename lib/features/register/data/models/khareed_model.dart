import 'package:hive/hive.dart';

part 'khareed_model.g.dart';

@HiveType(typeId: 10)
class KhareedModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late String itemName;

  @HiveField(3)
  late String vehicleNumber;

  @HiveField(4)
  late double weight;

  @HiveField(5)
  late String weightUnit;

  @HiveField(6)
  late double deduction;

  @HiveField(7)
  late double netWeight;

  @HiveField(8)
  late double ratePerUnit;

  @HiveField(9)
  late double totalAmount;

  @HiveField(10)
  late double jama;

  @HiveField(11)
  late double baqaya;

  @HiveField(12)
  late double sabhaBaqaya;

  @HiveField(13)
  late double netBaqaya;

  @HiveField(14)
  late String supplierName;

  @HiveField(15)
  late String note;

  @HiveField(16)
  late DateTime purchaseDate;

  @HiveField(17)
  late DateTime createdAt;

  @HiveField(18)
  late bool isDeleted;

  @HiveField(19, defaultValue: '')
  late String imagePath;
}
