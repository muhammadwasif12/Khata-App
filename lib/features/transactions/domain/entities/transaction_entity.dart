enum TxnType { credit, debit }

class TransactionEntity {
  final String id;
  final String partyId;
  final String businessId;
  final TxnType txnType;
  final double amount;
  final String note;
  final String paymentMethod;
  final String? attachmentPath;
  final String? attachmentType;
  final DateTime txnDate;
  final DateTime createdAt;
  final bool isDeleted;

  const TransactionEntity({
    required this.id,
    required this.partyId,
    required this.businessId,
    required this.txnType,
    required this.amount,
    this.note = '',
    this.paymentMethod = 'نقد',
    this.attachmentPath,
    this.attachmentType,
    required this.txnDate,
    required this.createdAt,
    this.isDeleted = false,
  });

  /// Payment method display labels and icons
  static const List<String> paymentMethods = [
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
