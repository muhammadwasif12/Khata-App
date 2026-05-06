import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/cash_entry_entity.dart';
import '../../domain/repositories/cashbook_repository.dart';
import '../models/cash_entry_model.dart';

class CashbookRepositoryImpl implements CashbookRepository {
  Box<CashEntryModel> get _box =>
      Hive.box<CashEntryModel>(AppConstants.cashEntryBox);

  @override
  Future<List<CashEntryEntity>> getEntriesByBusiness(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var entries = _box.values
        .where((e) => !e.isDeleted && e.businessId == businessId)
        .toList();
    if (from != null) {
      entries = entries
          .where(
            (e) =>
                e.entryDate.isAfter(from) || e.entryDate.isAtSameMomentAs(from),
          )
          .toList();
    }
    if (to != null) {
      entries = entries
          .where(
            (e) => e.entryDate.isBefore(to) || e.entryDate.isAtSameMomentAs(to),
          )
          .toList();
    }
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries.map(_toEntity).toList();
  }

  @override
  Future<CashEntryEntity?> getEntryById(String id) async {
    final model = _box.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<void> createEntry(CashEntryEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> updateEntry(CashEntryEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final model = _box.get(id);
    if (model != null) {
      model.isDeleted = true;
      await model.save();
    }
  }

  CashEntryEntity _toEntity(CashEntryModel model) => CashEntryEntity(
    id: model.id,
    businessId: model.businessId,
    cashType: CashType.values[model.cashType],
    amount: model.amount,
    note: model.note,
    paymentMethod: model.paymentMethod,
    personName: model.personName,
    accountTitle: model.accountTitle,
    attachmentPath: model.attachmentPath,
    attachmentType: model.attachmentType,
    entryDate: model.entryDate,
    createdAt: model.createdAt,
    isDeleted: model.isDeleted,
  );

  CashEntryModel _toModel(CashEntryEntity entity) => CashEntryModel(
    id: entity.id,
    businessId: entity.businessId,
    cashType: entity.cashType.index,
    amount: entity.amount,
    note: entity.note,
    paymentMethod: entity.paymentMethod,
    personName: entity.personName,
    accountTitle: entity.accountTitle,
    attachmentPath: entity.attachmentPath,
    attachmentType: entity.attachmentType,
    entryDate: entity.entryDate,
    createdAt: entity.createdAt,
    isDeleted: entity.isDeleted,
  );
}
