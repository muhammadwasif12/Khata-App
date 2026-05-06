import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/stock_entry_entity.dart';
import '../models/stock_entry_model.dart';

class StockEntryRepositoryImpl {
  Box<StockEntryModel> get _box =>
      Hive.box<StockEntryModel>(AppConstants.stockEntryBox);

  List<StockEntryEntity> getEntriesByProduct(String productId) {
    return _box.values
        .where((e) => e.productId == productId && !e.isDeleted)
        .map(_toEntity)
        .toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
  }

  List<StockEntryEntity> getEntriesByBusiness(String businessId) {
    return _box.values
        .where((e) => e.businessId == businessId && !e.isDeleted)
        .map(_toEntity)
        .toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
  }

  Future<void> addEntry(StockEntryEntity entity) async {
    final model = StockEntryModel(
      id: entity.id,
      productId: entity.productId,
      businessId: entity.businessId,
      entryType: entity.entryType == StockType.stockIn ? 0 : 1,
      quantity: entity.quantity,
      rate: entity.rate,
      totalAmount: entity.totalAmount,
      note: entity.note,
      entryDate: entity.entryDate,
      createdAt: entity.createdAt,
    );
    await _box.put(entity.id, model);
  }

  Future<void> deleteEntry(String id) async {
    final existing = _box.get(id);
    if (existing != null) {
      existing.isDeleted = true;
      await existing.save();
    }
  }

  StockEntryEntity _toEntity(StockEntryModel m) => StockEntryEntity(
        id: m.id,
        productId: m.productId,
        businessId: m.businessId,
        entryType: m.entryType == 0 ? StockType.stockIn : StockType.stockOut,
        quantity: m.quantity,
        rate: m.rate,
        totalAmount: m.totalAmount,
        note: m.note,
        entryDate: m.entryDate,
        createdAt: m.createdAt,
      );
}
