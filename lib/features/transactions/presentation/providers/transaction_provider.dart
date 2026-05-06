import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(),
);

class TransactionNotifier
    extends StateNotifier<AsyncValue<List<TransactionEntity>>> {
  final TransactionRepository _repository;
  final String _partyId;
  final String _businessId;
  final _uuid = const Uuid();

  TransactionNotifier(this._repository, this._partyId, this._businessId)
    : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final txns = await _repository.getTransactionsByParty(_partyId);
      state = AsyncValue.data(txns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(
    TxnType type,
    double amount,
    String note,
    DateTime date, {
    String paymentMethod = 'نقد',
    String? attachmentPath,
    String? attachmentType,
  }) async {
    final txn = TransactionEntity(
      id: _uuid.v4(),
      partyId: _partyId,
      businessId: _businessId,
      txnType: type,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
      attachmentPath: attachmentPath,
      attachmentType: attachmentType,
      txnDate: date,
      createdAt: DateTime.now(),
    );
    await _repository.createTransaction(txn);
    await loadTransactions();
  }

  Future<void> updateTransaction(
    String id,
    TxnType type,
    double amount,
    String note,
    DateTime date, {
    String paymentMethod = 'نقد',
    String? attachmentPath,
    String? attachmentType,
  }) async {
    final existing = await _repository.getTransactionById(id);
    if (existing != null) {
      final updated = TransactionEntity(
        id: existing.id,
        partyId: existing.partyId,
        businessId: existing.businessId,
        txnType: type,
        amount: amount,
        note: note,
        paymentMethod: paymentMethod,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
        txnDate: date,
        createdAt: existing.createdAt,
      );
      await _repository.updateTransaction(updated);
      await loadTransactions();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}

final transactionProviderFamily =
    StateNotifierProvider.family<
      TransactionNotifier,
      AsyncValue<List<TransactionEntity>>,
      (String, String)
    >((ref, params) {
      return TransactionNotifier(
        ref.watch(transactionRepositoryProvider),
        params.$1,
        params.$2,
      );
    });
