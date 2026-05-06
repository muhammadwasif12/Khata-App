import 'package:hive/hive.dart';

part 'business_model.g.dart';

@HiveType(typeId: 0)
class BusinessModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  late bool isDeleted;

  @HiveField(6)
  String ownerName;

  @HiveField(7)
  String phone;

  @HiveField(8)
  String address;

  @HiveField(9)
  String currency;

  BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.currency = 'PKR',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });
}
