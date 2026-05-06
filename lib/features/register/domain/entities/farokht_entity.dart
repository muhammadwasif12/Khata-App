class FarokhtEntity {
  final String id;
  final String businessId;
  final String itemName;
  final String buyerName;
  final String cardNumber;
  final double weight;
  final String weightUnit;
  final double ratePerUnit;
  final double totalAmount;
  final double creditAmount;
  final double debitAmount;
  final double tafazul;
  final int paymentStatus; // 0=ادھار | 1=نقد | 2=جزوی ادائیگی
  final String note;
  final DateTime saleDate;
  final DateTime createdAt;
  final bool isDeleted;
  final String customPaymentType;
  final String imagePath;

  const FarokhtEntity({
    required this.id,
    required this.businessId,
    required this.itemName,
    required this.buyerName,
    this.cardNumber = '',
    required this.weight,
    required this.weightUnit,
    required this.ratePerUnit,
    required this.totalAmount,
    this.creditAmount = 0,
    this.debitAmount = 0,
    this.tafazul = 0,
    required this.paymentStatus,
    this.customPaymentType = '',
    this.note = '',
    required this.saleDate,
    required this.createdAt,
    this.isDeleted = false,
    this.imagePath = '',
  });
}
