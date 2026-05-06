import 'package:hive/hive.dart';
import '../../domain/entities/khareed_entity.dart';
import '../../domain/repositories/khareed_repository.dart';
import '../models/khareed_model.dart';

class KhareedRepositoryImpl implements KhareedRepository {
  final Box<KhareedModel> _box;

  KhareedRepositoryImpl(this._box);

  @override
  Future<List<KhareedEntity>> getAllByBusiness(String businessId, {DateTime? from, DateTime? to}) async {
    return _box.values
        .where((e) => e.businessId == businessId && !e.isDeleted)
        .map(_toEntity)
        .toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  @override
  Future<KhareedEntity?> getById(String id) async {
    final model = _box.get(id);
    if (model != null && !model.isDeleted) {
      return _toEntity(model);
    }
    return null;
  }

  @override
  Future<void> create(KhareedEntity entity) async {
    final model = _fromEntity(entity);
    await _box.put(model.id, model);
  }

  @override
  Future<void> update(KhareedEntity entity) async {
    if (_box.containsKey(entity.id)) {
      final model = _fromEntity(entity);
      await _box.put(entity.id, model);
    }
  }

  @override
  Future<void> delete(String id) async {
    final model = _box.get(id);
    if (model != null) {
      model.isDeleted = true;
      await model.save();
    }
  }

  KhareedEntity _toEntity(KhareedModel m) {
    return KhareedEntity(
      id: m.id,
      businessId: m.businessId,
      itemName: m.itemName,
      vehicleNumber: m.vehicleNumber,
      weight: m.weight,
      weightUnit: m.weightUnit,
      deduction: m.deduction,
      netWeight: m.netWeight,
      ratePerUnit: m.ratePerUnit,
      totalAmount: m.totalAmount,
      jama: m.jama,
      baqaya: m.baqaya,
      sabhaBaqaya: m.sabhaBaqaya,
      netBaqaya: m.netBaqaya,
      supplierName: m.supplierName,
      note: m.note,
      purchaseDate: m.purchaseDate,
      createdAt: m.createdAt,
      isDeleted: m.isDeleted,
      imagePath: m.imagePath,
    );
  }

  KhareedModel _fromEntity(KhareedEntity e) {
    return KhareedModel()
      ..id = e.id
      ..businessId = e.businessId
      ..itemName = e.itemName
      ..vehicleNumber = e.vehicleNumber
      ..weight = e.weight
      ..weightUnit = e.weightUnit
      ..deduction = e.deduction
      ..netWeight = e.netWeight
      ..ratePerUnit = e.ratePerUnit
      ..totalAmount = e.totalAmount
      ..jama = e.jama
      ..baqaya = e.baqaya
      ..sabhaBaqaya = e.sabhaBaqaya
      ..netBaqaya = e.netBaqaya
      ..supplierName = e.supplierName
      ..note = e.note
      ..purchaseDate = e.purchaseDate
      ..createdAt = e.createdAt
      ..isDeleted = e.isDeleted
      ..imagePath = e.imagePath;
  }
}
