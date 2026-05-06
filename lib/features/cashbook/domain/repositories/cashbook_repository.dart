import '../entities/cash_entry_entity.dart';

abstract class CashbookRepository {
  Future<List<CashEntryEntity>> getEntriesByBusiness(
    String businessId, {
    DateTime? from,
    DateTime? to,
  });
  Future<CashEntryEntity?> getEntryById(String id);
  Future<void> createEntry(CashEntryEntity entry);
  Future<void> updateEntry(CashEntryEntity entry);
  Future<void> deleteEntry(String id);
}
