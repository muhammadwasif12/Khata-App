import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/stock_entry_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/stock_entry_entity.dart';

// ─── Product Providers ───

final productRepositoryProvider = Provider((ref) => ProductRepositoryImpl());
final stockEntryRepositoryProvider =
    Provider((ref) => StockEntryRepositoryImpl());

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductEntity>>>(
  (ref) {
    final activeId = ref.watch(activeBusinessIdProvider);
    return ProductsNotifier(ref, activeId);
  },
);

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
  final Ref ref;
  final String? businessId;
  final _repo = ProductRepositoryImpl();

  ProductsNotifier(this.ref, this.businessId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    if (businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = AsyncValue.data(_repo.getProducts(businessId!));
  }

  Future<void> addProduct({
    required String name,
    required String unit,
    required double purchasePrice,
    required double salePrice,
    required double openingStock,
    required double lowStockAlert,
  }) async {
    if (businessId == null) return;
    final entity = ProductEntity(
      id: const Uuid().v4(),
      businessId: businessId!,
      name: name,
      unit: unit,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      currentStock: openingStock,
      lowStockAlert: lowStockAlert,
      createdAt: DateTime.now(),
    );
    await _repo.addProduct(entity);
    _load();
  }

  Future<void> updateProduct(
    String id, {
    required String name,
    required String unit,
    required double purchasePrice,
    required double salePrice,
    required double lowStockAlert,
  }) async {
    final existing = _repo.getProductById(id);
    if (existing == null) return;
    final updated = ProductEntity(
      id: id,
      businessId: existing.businessId,
      name: name,
      unit: unit,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      currentStock: existing.currentStock,
      lowStockAlert: lowStockAlert,
      createdAt: existing.createdAt,
    );
    await _repo.updateProduct(updated);
    _load();
  }

  Future<void> deleteProduct(String id) async {
    await _repo.deleteProduct(id);
    _load();
  }

  void refresh() => _load();
}

// ─── Stock Entry Providers ───

final stockEntriesProvider = StateNotifierProvider.family<
    StockEntriesNotifier, AsyncValue<List<StockEntryEntity>>, String>(
  (ref, productId) => StockEntriesNotifier(ref, productId),
);

class StockEntriesNotifier
    extends StateNotifier<AsyncValue<List<StockEntryEntity>>> {
  final Ref ref;
  final String productId;
  final _entryRepo = StockEntryRepositoryImpl();
  final _productRepo = ProductRepositoryImpl();

  StockEntriesNotifier(this.ref, this.productId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    state = AsyncValue.data(_entryRepo.getEntriesByProduct(productId));
  }

  Future<void> addStockEntry({
    required StockType entryType,
    required double quantity,
    required double rate,
    required String note,
    required DateTime date,
  }) async {
    final product = _productRepo.getProductById(productId);
    if (product == null) return;

    final entity = StockEntryEntity(
      id: const Uuid().v4(),
      productId: productId,
      businessId: product.businessId,
      entryType: entryType,
      quantity: quantity,
      rate: rate,
      totalAmount: quantity * rate,
      note: note,
      entryDate: date,
      createdAt: DateTime.now(),
    );
    await _entryRepo.addEntry(entity);

    // Update product stock
    final change =
        entryType == StockType.stockIn ? quantity : -quantity;
    await _productRepo.updateStock(productId, change);

    _load();
    // Refresh products list
    ref.read(productsProvider.notifier).refresh();
  }

  Future<void> deleteEntry(StockEntryEntity entry) async {
    await _entryRepo.deleteEntry(entry.id);
    // Reverse the stock change
    final reverseChange =
        entry.entryType == StockType.stockIn ? -entry.quantity : entry.quantity;
    await _productRepo.updateStock(productId, reverseChange);
    _load();
    ref.read(productsProvider.notifier).refresh();
  }
}
