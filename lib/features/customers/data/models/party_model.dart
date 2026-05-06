import 'package:hive/hive.dart';

part 'party_model.g.dart';

@HiveType(typeId: 1)
class PartyModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String businessId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String phone;

  @HiveField(4)
  late double openingBalance;

  @HiveField(5)
  late bool isOpeningCredit;

  @HiveField(6)
  late int partyType;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late bool isDeleted;

  PartyModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone = '',
    this.openingBalance = 0,
    this.isOpeningCredit = true,
    required this.partyType,
    required this.createdAt,
    this.isDeleted = false,
  });
}
