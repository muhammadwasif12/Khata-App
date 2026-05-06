import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../models/business_model.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  Box<BusinessModel> get _box =>
      Hive.box<BusinessModel>(AppConstants.businessBox);

  @override
  Future<List<BusinessEntity>> getAllBusinesses() async {
    final businesses = _box.values.where((b) => !b.isDeleted).toList();
    return businesses.map(_toEntity).toList();
  }

  @override
  Future<BusinessEntity?> getBusinessById(String id) async {
    final model = _box.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<void> createBusiness(BusinessEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> updateBusiness(BusinessEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> deleteBusiness(String id) async {
    final model = _box.get(id);
    if (model != null) {
      model.isDeleted = true;
      model.updatedAt = DateTime.now();
      await model.save();
    }
  }

  BusinessEntity _toEntity(BusinessModel model) => BusinessEntity(
    id: model.id,
    name: model.name,
    type: model.type,
    ownerName: model.ownerName,
    phone: model.phone,
    address: model.address,
    currency: model.currency,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    isDeleted: model.isDeleted,
  );

  BusinessModel _toModel(BusinessEntity entity) => BusinessModel(
    id: entity.id,
    name: entity.name,
    type: entity.type,
    ownerName: entity.ownerName,
    phone: entity.phone,
    address: entity.address,
    currency: entity.currency,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    isDeleted: entity.isDeleted,
  );
}
