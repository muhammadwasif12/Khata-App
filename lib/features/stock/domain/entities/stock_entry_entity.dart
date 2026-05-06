/// Stock Entry Entity — represents a single stock IN or OUT movement.
enum StockType { stockIn, stockOut }

class StockEntryEntity {
  final String id;
  final String productId;
  final String businessId;
  final StockType entryType;
  final double quantity;
  final double rate;
  final double totalAmount;
  final String note;
  final DateTime entryDate;
  final DateTime createdAt;

  const StockEntryEntity({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.entryType,
    required this.quantity,
    required this.rate,
    required this.totalAmount,
    required this.note,
    required this.entryDate,
    required this.createdAt,
  });
}
