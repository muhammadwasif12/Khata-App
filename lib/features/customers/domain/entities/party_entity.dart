enum PartyType { customer, supplier }

class PartyEntity {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final double openingBalance;
  final bool isOpeningCredit;
  final PartyType partyType;
  final DateTime createdAt;
  final bool isDeleted;

  const PartyEntity({
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
