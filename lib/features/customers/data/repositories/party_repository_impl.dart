import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/party_entity.dart';
import '../../domain/repositories/party_repository.dart';
import '../models/party_model.dart';

class PartyRepositoryImpl implements PartyRepository {
  Box<PartyModel> get _box => Hive.box<PartyModel>(AppConstants.partyBox);

  @override
  Future<List<PartyEntity>> getPartiesByBusiness(
    String businessId, {
    PartyType? partyType,
  }) async {
    var parties = _box.values
        .where((p) => !p.isDeleted && p.businessId == businessId)
        .toList();
    if (partyType != null) {
      parties = parties.where((p) => p.partyType == partyType.index).toList();
    }
    return parties.map(_toEntity).toList();
  }

  @override
  Future<PartyEntity?> getPartyById(String id) async {
    final model = _box.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<void> createParty(PartyEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> updateParty(PartyEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> deleteParty(String id) async {
    final model = _box.get(id);
    if (model != null) {
      model.isDeleted = true;
      await model.save();
    }
  }

  PartyEntity _toEntity(PartyModel model) => PartyEntity(
    id: model.id,
    businessId: model.businessId,
    name: model.name,
    phone: model.phone,
    openingBalance: model.openingBalance,
    isOpeningCredit: model.isOpeningCredit,
    partyType: PartyType.values[model.partyType],
    createdAt: model.createdAt,
    isDeleted: model.isDeleted,
  );

  PartyModel _toModel(PartyEntity entity) => PartyModel(
    id: entity.id,
    businessId: entity.businessId,
    name: entity.name,
    phone: entity.phone,
    openingBalance: entity.openingBalance,
    isOpeningCredit: entity.isOpeningCredit,
    partyType: entity.partyType.index,
    createdAt: entity.createdAt,
    isDeleted: entity.isDeleted,
  );
}
