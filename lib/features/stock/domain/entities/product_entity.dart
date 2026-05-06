/// Product Entity — domain representation of a product in inventory.
class ProductEntity {
  final String id;
  final String businessId;
  final String name;
  final String unit;
  final double purchasePrice;
  final double salePrice;
  final double currentStock;
  final double lowStockAlert;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.businessId,
    required this.name,
    required this.unit,
    required this.purchasePrice,
    required this.salePrice,
    required this.currentStock,
    required this.lowStockAlert,
    required this.createdAt,
  });

  bool get isLowStock => currentStock <= lowStockAlert && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  double get profitPerUnit => salePrice - purchasePrice;
  double get stockValue => currentStock * purchasePrice;
}
