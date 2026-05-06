import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../data/repositories/farokht_repository_impl.dart';
import '../../domain/entities/farokht_entity.dart';
import '../../domain/repositories/farokht_repository.dart';

final farokhtRepositoryProvider = Provider<FarokhtRepository>(
  (ref) => FarokhtRepositoryImpl(),
);

final farokhtProvider =
    StateNotifierProvider<FarokhtNotifier, AsyncValue<List<FarokhtEntity>>>((
      ref,
    ) {
      final businessId = ref.watch(activeBusinessIdProvider);
      return FarokhtNotifier(
        ref.watch(farokhtRepositoryProvider),
        businessId,
      );
    });

/// Sum of totalAmount this month
final totalFarokhtProvider = Provider<double>((ref) {
  final records = ref.watch(farokhtProvider).value ?? [];
  final now = DateTime.now();
  return records
      .where((r) =>
          r.saleDate.month == now.month && r.saleDate.year == now.year)
      .fold(0.0, (sum, r) => sum + r.totalAmount);
});

/// Sum of creditAmount (received) this month
final totalCreditProvider = Provider<double>((ref) {
  final records = ref.watch(farokhtProvider).value ?? [];
  final now = DateTime.now();
  return records
      .where((r) =>
          r.saleDate.month == now.month && r.saleDate.year == now.year)
      .fold(0.0, (sum, r) => sum + r.creditAmount);
});

/// Sum of debitAmount (pending) this month
final totalDebitProvider = Provider<double>((ref) {
  final records = ref.watch(farokhtProvider).value ?? [];
  final now = DateTime.now();
  return records
      .where((r) =>
          r.saleDate.month == now.month && r.saleDate.year == now.year)
      .fold(0.0, (sum, r) => sum + r.debitAmount);
});

/// Sum of tafazul (profit) this month
final farokhtProfitProvider = Provider<double>((ref) {
  final records = ref.watch(farokhtProvider).value ?? [];
  final now = DateTime.now();
  return records
      .where((r) =>
          r.saleDate.month == now.month && r.saleDate.year == now.year)
      .fold(0.0, (sum, r) => sum + r.tafazul);
});

class FarokhtNotifier
    extends StateNotifier<AsyncValue<List<FarokhtEntity>>> {
  final FarokhtRepository _repository;
  final String? _businessId;
  final _uuid = const Uuid();

  FarokhtNotifier(this._repository, this._businessId)
      : super(const AsyncValue.loading()) {
    if (_businessId != null) {
      loadAll();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadAll({DateTime? from, DateTime? to}) async {
    if (_businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getAllByBusiness(
        _businessId!,
        from: from,
        to: to,
      );
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    required String itemName,
    required String buyerName,
    String cardNumber = '',
    required double weight,
    required String weightUnit,
    required double ratePerUnit,
    required double creditAmount,
    required double debitAmount,
    double tafazul = 0,
    required int paymentStatus,
    String customPaymentType = '',
    String note = '',
    required DateTime saleDate,
    String imagePath = '',
  }) async {
    if (_businessId == null) return;
    final totalAmount = weight * ratePerUnit;
    final entity = FarokhtEntity(
      id: _uuid.v4(),
      businessId: _businessId!,
      itemName: itemName,
      buyerName: buyerName,
      cardNumber: cardNumber,
      weight: weight,
      weightUnit: weightUnit,
      ratePerUnit: ratePerUnit,
      totalAmount: totalAmount,
      creditAmount: creditAmount,
      debitAmount: debitAmount,
      tafazul: tafazul,
      paymentStatus: paymentStatus,
      customPaymentType: customPaymentType,
      note: note,
      saleDate: saleDate,
      createdAt: DateTime.now(),
      imagePath: imagePath,
    );
    await _repository.create(entity);
    await loadAll();
  }

  Future<void> update({
    required String id,
    required String itemName,
    required String buyerName,
    String cardNumber = '',
    required double weight,
    required String weightUnit,
    required double ratePerUnit,
    required double creditAmount,
    required double debitAmount,
    double tafazul = 0,
    required int paymentStatus,
    String customPaymentType = '',
    String note = '',
    required DateTime saleDate,
    String imagePath = '',
  }) async {
    final existing = await _repository.getById(id);
    if (existing == null) return;
    final totalAmount = weight * ratePerUnit;
    final updated = FarokhtEntity(
      id: existing.id,
      businessId: existing.businessId,
      itemName: itemName,
      buyerName: buyerName,
      cardNumber: cardNumber,
      weight: weight,
      weightUnit: weightUnit,
      ratePerUnit: ratePerUnit,
      totalAmount: totalAmount,
      creditAmount: creditAmount,
      debitAmount: debitAmount,
      tafazul: tafazul,
      paymentStatus: paymentStatus,
      customPaymentType: customPaymentType,
      note: note,
      saleDate: saleDate,
      createdAt: existing.createdAt,
      imagePath: imagePath.isEmpty ? existing.imagePath : imagePath,
    );
    await _repository.update(updated);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadAll();
  }
}
