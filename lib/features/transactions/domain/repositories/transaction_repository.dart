import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactionsByParty(String partyId);
  Future<List<TransactionEntity>> getTransactionsByBusiness(String businessId);
  Future<TransactionEntity?> getTransactionById(String id);
  Future<void> createTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
}
