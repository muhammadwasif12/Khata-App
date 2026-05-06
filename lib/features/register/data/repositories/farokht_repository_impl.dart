import 'package:hive/hive.dart';
import '../../domain/entities/farokht_entity.dart';
import '../../domain/repositories/farokht_repository.dart';
import '../models/farokht_model.dart';

class FarokhtRepositoryImpl implements FarokhtRepository {
  static const String _boxName = 'farokht';

  Box<FarokhtModel> get _box => Hive.box<FarokhtModel>(_boxName);

  @override
  Future<List<FarokhtEntity>> getAllByBusiness(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var entries = _box.values
        .where((e) => !e.isDeleted && e.businessId == businessId)
        .toList();
    if (from != null) {
      final fromStart = DateTime(from.year, from.month, from.day);
      entries = entries
          .where((e) =>
              e.saleDate.isAfter(fromStart) ||
              e.saleDate.isAtSameMomentAs(fromStart))
          .toList();
    }
    if (to != null) {
      final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
      entries = entries
          .where((e) =>
              e.saleDate.isBefore(toEnd) ||
              e.saleDate.isAtSameMomentAs(toEnd))
          .toList();
    }
    entries.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return entries.map(_toEntity).toList();
  }

  @override
  Future<FarokhtEntity?> getById(String id) async {
    final model = _box.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<void> create(FarokhtEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> update(FarokhtEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> delete(String id) async {
    final model = _box.get(id);
    if (model != null) {
      model.isDeleted = true;
      await model.save();
    }
  }

  FarokhtEntity _toEntity(FarokhtModel m) => FarokhtEntity(
        id: m.id,
        businessId: m.businessId,
        itemName: m.itemName,
        buyerName: m.buyerName,
        cardNumber: m.cardNumber,
        weight: m.weight,
        weightUnit: m.weightUnit,
        ratePerUnit: m.ratePerUnit,
        totalAmount: m.totalAmount,
        creditAmount: m.creditAmount,
        debitAmount: m.debitAmount,
        tafazul: m.tafazul,
        paymentStatus: m.paymentStatus,
        note: m.note,
        saleDate: m.saleDate,
        createdAt: m.createdAt,
        isDeleted: m.isDeleted,
        customPaymentType: m.customPaymentType,
        imagePath: m.imagePath,
      );

  FarokhtModel _toModel(FarokhtEntity e) => FarokhtModel(
        id: e.id,
        businessId: e.businessId,
        itemName: e.itemName,
        buyerName: e.buyerName,
        cardNumber: e.cardNumber,
        weight: e.weight,
        weightUnit: e.weightUnit,
        ratePerUnit: e.ratePerUnit,
        totalAmount: e.totalAmount,
        creditAmount: e.creditAmount,
        debitAmount: e.debitAmount,
        tafazul: e.tafazul,
        paymentStatus: e.paymentStatus,
        note: e.note,
        saleDate: e.saleDate,
        createdAt: e.createdAt,
        isDeleted: e.isDeleted,
        customPaymentType: e.customPaymentType,
        imagePath: e.imagePath,
      );
}
