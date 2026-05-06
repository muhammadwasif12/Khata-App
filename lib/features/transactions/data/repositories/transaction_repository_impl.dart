import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  Box<TransactionModel> get _box =>
      Hive.box<TransactionModel>(AppConstants.transactionBox);

  @override
  Future<List<TransactionEntity>> getTransactionsByParty(String partyId) async {
    final txns = _box.values
        .where((t) => !t.isDeleted && t.partyId == partyId)
        .toList();
    txns.sort((a, b) => a.txnDate.compareTo(b.txnDate));
    return txns.map(_toEntity).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByBusiness(
    String businessId,
  ) async {
    final txns = _box.values
        .where((t) => !t.isDeleted && t.businessId == businessId)
        .toList();
    return txns.map(_toEntity).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final model = _box.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<void> createTransaction(TransactionEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> updateTransaction(TransactionEntity entity) async {
    final model = _toModel(entity);
    await _box.put(entity.id, model);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final model = _box.get(id);
    if (model != null) {
      model.isDeleted = true;
      await model.save();
    }
  }

  TransactionEntity _toEntity(TransactionModel model) => TransactionEntity(
    id: model.id,
    partyId: model.partyId,
    businessId: model.businessId,
    txnType: TxnType.values[model.txnType],
    amount: model.amount,
    note: model.note,
    paymentMethod: model.paymentMethod,
    attachmentPath: model.attachmentPath,
    attachmentType: model.attachmentType,
    txnDate: model.txnDate,
    createdAt: model.createdAt,
    isDeleted: model.isDeleted,
  );

  TransactionModel _toModel(TransactionEntity entity) => TransactionModel(
    id: entity.id,
    partyId: entity.partyId,
    businessId: entity.businessId,
    txnType: entity.txnType.index,
    amount: entity.amount,
    note: entity.note,
    paymentMethod: entity.paymentMethod,
    attachmentPath: entity.attachmentPath,
    attachmentType: entity.attachmentType,
    txnDate: entity.txnDate,
    createdAt: entity.createdAt,
    isDeleted: entity.isDeleted,
  );
}
