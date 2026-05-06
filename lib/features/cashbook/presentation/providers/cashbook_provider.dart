import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../data/repositories/cashbook_repository_impl.dart';
import '../../domain/entities/cash_entry_entity.dart';
import '../../domain/repositories/cashbook_repository.dart';

final cashbookRepositoryProvider = Provider<CashbookRepository>(
  (ref) => CashbookRepositoryImpl(),
);

final cashEntriesProvider =
    StateNotifierProvider<CashbookNotifier, AsyncValue<List<CashEntryEntity>>>((
      ref,
    ) {
      final businessId = ref.watch(activeBusinessIdProvider);
      return CashbookNotifier(
        ref.watch(cashbookRepositoryProvider),
        businessId,
      );
    });

class CashbookNotifier
    extends StateNotifier<AsyncValue<List<CashEntryEntity>>> {
  final CashbookRepository _repository;
  final String? _businessId;
  final _uuid = const Uuid();

  CashbookNotifier(this._repository, this._businessId)
    : super(const AsyncValue.loading()) {
    if (_businessId != null) {
      loadEntries();
    }
  }

  Future<void> loadEntries() async {
    if (_businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getEntriesByBusiness(_businessId!);
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(
    CashType type,
    double amount,
    String note,
    DateTime date, {
    String paymentMethod = 'نقد',
    String? personName,
    String? accountTitle,
    String? attachmentPath,
    String? attachmentType,
  }) async {
    if (_businessId == null) return;
    final entry = CashEntryEntity(
      id: _uuid.v4(),
      businessId: _businessId!,
      cashType: type,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
      personName: personName,
      accountTitle: accountTitle,
      attachmentPath: attachmentPath,
      attachmentType: attachmentType,
      entryDate: date,
      createdAt: DateTime.now(),
    );
    await _repository.createEntry(entry);
    await loadEntries();
  }

  Future<void> updateEntry(
    String id,
    CashType type,
    double amount,
    String note,
    DateTime date, {
    String paymentMethod = 'نقد',
    String? personName,
    String? accountTitle,
    String? attachmentPath,
    String? attachmentType,
  }) async {
    final existing = await _repository.getEntryById(id);
    if (existing != null) {
      final updated = CashEntryEntity(
        id: existing.id,
        businessId: existing.businessId,
        cashType: type,
        amount: amount,
        note: note,
        paymentMethod: paymentMethod,
        personName: personName,
        accountTitle: accountTitle,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
        entryDate: date,
        createdAt: existing.createdAt,
      );
      await _repository.updateEntry(updated);
      await loadEntries();
    }
  }

  Future<void> deleteEntry(String id) async {
    await _repository.deleteEntry(id);
    await loadEntries();
  }
}
