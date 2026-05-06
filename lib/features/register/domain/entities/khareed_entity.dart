class KhareedEntity {
  final String id;
  final String businessId;
  final String itemName;
  final String vehicleNumber;
  final double weight;
  final String weightUnit;
  final double deduction;
  final double netWeight;
  final double ratePerUnit;
  final double totalAmount;
  final double jama;
  final double baqaya;
  final double sabhaBaqaya;
  final double netBaqaya;
  final String supplierName;
  final String note;
  final DateTime purchaseDate;
  final DateTime createdAt;
  final bool isDeleted;
  final String imagePath;

  KhareedEntity({
    required this.id,
    required this.businessId,
    required this.itemName,
    required this.vehicleNumber,
    required this.weight,
    required this.weightUnit,
    required this.deduction,
    required this.netWeight,
    required this.ratePerUnit,
    required this.totalAmount,
    required this.jama,
    required this.baqaya,
    required this.sabhaBaqaya,
    required this.netBaqaya,
    required this.supplierName,
    required this.note,
    required this.purchaseDate,
    required this.createdAt,
    required this.isDeleted,
    this.imagePath = '',
  });
}
