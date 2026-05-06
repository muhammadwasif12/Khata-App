import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/product_entity.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl {
  Box<ProductModel> get _box =>
      Hive.box<ProductModel>(AppConstants.productBox);

  List<ProductEntity> getProducts(String businessId) {
    return _box.values
        .where((p) => p.businessId == businessId && !p.isDeleted)
        .map(_toEntity)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ProductEntity? getProductById(String id) {
    final model = _box.values.where((p) => p.id == id && !p.isDeleted).firstOrNull;
    return model != null ? _toEntity(model) : null;
  }

  Future<void> addProduct(ProductEntity entity) async {
    final model = ProductModel(
      id: entity.id,
      businessId: entity.businessId,
      name: entity.name,
      unit: entity.unit,
      purchasePrice: entity.purchasePrice,
      salePrice: entity.salePrice,
      currentStock: entity.currentStock,
      lowStockAlert: entity.lowStockAlert,
      createdAt: entity.createdAt,
    );
    await _box.put(entity.id, model);
  }

  Future<void> updateProduct(ProductEntity entity) async {
    final existing = _box.get(entity.id);
    if (existing != null) {
      existing.name = entity.name;
      existing.unit = entity.unit;
      existing.purchasePrice = entity.purchasePrice;
      existing.salePrice = entity.salePrice;
      existing.currentStock = entity.currentStock;
      existing.lowStockAlert = entity.lowStockAlert;
      await existing.save();
    }
  }

  Future<void> updateStock(String productId, double quantityChange) async {
    final existing = _box.get(productId);
    if (existing != null) {
      existing.currentStock += quantityChange;
      await existing.save();
    }
  }

  Future<void> deleteProduct(String id) async {
    final existing = _box.get(id);
    if (existing != null) {
      existing.isDeleted = true;
      await existing.save();
    }
  }

  ProductEntity _toEntity(ProductModel m) => ProductEntity(
        id: m.id,
        businessId: m.businessId,
        name: m.name,
        unit: m.unit,
        purchasePrice: m.purchasePrice,
        salePrice: m.salePrice,
        currentStock: m.currentStock,
        lowStockAlert: m.lowStockAlert,
        createdAt: m.createdAt,
      );
}
