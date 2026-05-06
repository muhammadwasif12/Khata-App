/// Invoice Entity — domain representation of an invoice/bill.
enum InvoiceStatus { unpaid, partial, paid }

class InvoiceEntity {
  final String id;
  final String businessId;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final String? partyId;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final InvoiceStatus status;
  final DateTime invoiceDate;
  final DateTime createdAt;
  final String note;
  final String vehicleNumber;

  const InvoiceEntity({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    this.partyId,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.invoiceDate,
    required this.createdAt,
    required this.note,
    this.vehicleNumber = '',
  });

  double get balanceAmount => totalAmount - paidAmount;
  bool get isPaid => status == InvoiceStatus.paid;
}
