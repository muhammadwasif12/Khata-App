/// Invoice Item Entity — a single line item in an invoice.
class InvoiceItemEntity {
  final String id;
  final String invoiceId;
  final String productName;
  final String? productId;
  final double quantity;
  final double rate;
  final double amount;
  final String unit;

  const InvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    required this.productName,
    this.productId,
    required this.quantity,
    required this.rate,
    required this.amount,
    required this.unit,
  });
}
