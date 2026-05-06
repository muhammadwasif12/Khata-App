class BusinessEntity {
  final String id;
  final String name;
  final String type;
  final String ownerName;
  final String phone;
  final String address;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const BusinessEntity({
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
