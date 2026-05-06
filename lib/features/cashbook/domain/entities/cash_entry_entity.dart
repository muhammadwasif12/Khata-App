enum CashType { cashIn, cashOut }

class CashEntryEntity {
  final String id;
  final String businessId;
  final CashType cashType;
  final double amount;
  final String note;
  final String paymentMethod;
  final String? personName;
  final String? accountTitle;
  final String? attachmentPath;
  final String? attachmentType;
  final DateTime entryDate;
  final DateTime createdAt;
  final bool isDeleted;

  const CashEntryEntity({
    required this.id,
    required this.businessId,
    required this.cashType,
    required this.amount,
    this.note = '',
    this.paymentMethod = 'نقد',
    this.personName,
    this.accountTitle,
    this.attachmentPath,
    this.attachmentType,
    required this.entryDate,
    required this.createdAt,
    this.isDeleted = false,
  });

  /// Available payment methods for cash entries
  static const List<String> cashPaymentMethods = [
    'نقد',
    'ایزی پیسہ',
    'جیز کیش',
    'میزان بینک',
    'ایچ بی ایل',
    'یو بی ایل',
    'ایم سی بی',
    'دیگر',
  ];
}
