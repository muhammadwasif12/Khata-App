import 'package:hive/hive.dart';
import '../../domain/entities/kharcha_entity.dart';
import '../../domain/repositories/kharcha_repository.dart';
import '../models/kharcha_model.dart';

class KharchaRepositoryImpl implements KharchaRepository {
  final Box<KharchaModel> _box;

  KharchaRepositoryImpl(this._box);

  @override
  Future<List<KharchaEntity>> getAllByBusiness(String businessId, {DateTime? from, DateTime? to}) async {
    return _box.values
        .where((e) => e.businessId == businessId && !e.isDeleted)
        .map(_toEntity)
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  @override
  Future<KharchaEntity?> getById(String id) async {
    final model = _box.get(id);
    if (model != null && !model.isDeleted) {
      return _toEntity(model);
    }
    return null;
  }

  @override
  Future<void> create(KharchaEntity entity) async {
    final model = _fromEntity(entity);
    await _box.put(model.id, model);
  }

  @override
  Future<void> update(KharchaEntity entity) async {
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

  KharchaEntity _toEntity(KharchaModel m) {
    return KharchaEntity(
      id: m.id,
      businessId: m.businessId,
      category: m.category,
      customCategory: m.customCategory,
      amount: m.amount,
      note: m.note,
      paidTo: m.paidTo,
      vehicleNumber: m.vehicleNumber,
      driverName: m.driverName,
      expenseDate: m.expenseDate,
      createdAt: m.createdAt,
      isDeleted: m.isDeleted,
      imagePath: m.imagePath,
    );
  }

  KharchaModel _fromEntity(KharchaEntity e) {
    return KharchaModel()
      ..id = e.id
      ..businessId = e.businessId
      ..category = e.category
      ..customCategory = e.customCategory
      ..amount = e.amount
      ..note = e.note
      ..paidTo = e.paidTo
      ..vehicleNumber = e.vehicleNumber
      ..driverName = e.driverName
      ..expenseDate = e.expenseDate
      ..createdAt = e.createdAt
      ..isDeleted = e.isDeleted
      ..imagePath = e.imagePath;
  }
}
