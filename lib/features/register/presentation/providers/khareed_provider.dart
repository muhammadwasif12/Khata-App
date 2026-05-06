import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/khareed_model.dart';
import '../../data/repositories/khareed_repository_impl.dart';
import '../../domain/entities/khareed_entity.dart';
import '../../domain/usecases/khareed/add_khareed.dart';
import '../../domain/usecases/khareed/delete_khareed.dart';
import '../../domain/usecases/khareed/get_all_khareed.dart';
import '../../domain/usecases/khareed/update_khareed.dart';
import '../../../business/presentation/providers/business_provider.dart';

final khareedBoxProvider = Provider<Box<KhareedModel>>((ref) {
  return Hive.box<KhareedModel>('khareed');
});

final khareedRepositoryProvider = Provider((ref) {
  return KhareedRepositoryImpl(ref.read(khareedBoxProvider));
});

final getAllKhareedUseCaseProvider = Provider((ref) {
  return GetAllKhareed(ref.read(khareedRepositoryProvider));
});
final addKhareedUseCaseProvider = Provider((ref) {
  return AddKhareed(ref.read(khareedRepositoryProvider));
});
final updateKhareedUseCaseProvider = Provider((ref) {
  return UpdateKhareed(ref.read(khareedRepositoryProvider));
});
final deleteKhareedUseCaseProvider = Provider((ref) {
  return DeleteKhareed(ref.read(khareedRepositoryProvider));
});

class KhareedNotifier extends StateNotifier<AsyncValue<List<KhareedEntity>>> {
  final Ref _ref;
  final String _businessId;

  KhareedNotifier(this._ref, this._businessId) : super(const AsyncValue.loading()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final getUseCase = _ref.read(getAllKhareedUseCaseProvider);
      final records = await getUseCase(_businessId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    required String itemName,
    required String vehicleNumber,
    required double weight,
    required String weightUnit,
    required double deduction,
    required double ratePerUnit,
    required double jama,
    required double sabhaBaqaya,
    required String supplierName,
    required String note,
    required DateTime purchaseDate,
    String imagePath = '',
  }) async {
    final netWeight = weight - deduction;
    final totalAmount = netWeight * ratePerUnit;
    final baqaya = totalAmount - jama;
    final netBaqaya = baqaya + sabhaBaqaya;

    final entry = KhareedEntity(
      id: const Uuid().v4(),
      businessId: _businessId,
      itemName: itemName,
      vehicleNumber: vehicleNumber,
      weight: weight,
      weightUnit: weightUnit,
      deduction: deduction,
      netWeight: netWeight,
      ratePerUnit: ratePerUnit,
      totalAmount: totalAmount,
      jama: jama,
      baqaya: baqaya,
      sabhaBaqaya: sabhaBaqaya,
      netBaqaya: netBaqaya,
      supplierName: supplierName,
      note: note,
      purchaseDate: purchaseDate,
      createdAt: DateTime.now(),
      isDeleted: false,
      imagePath: imagePath,
    );

    await _ref.read(addKhareedUseCaseProvider)(entry);
    await _loadAll();
  }

  Future<void> update({
    required String id,
    required String itemName,
    required String vehicleNumber,
    required double weight,
    required String weightUnit,
    required double deduction,
    required double ratePerUnit,
    required double jama,
    required double sabhaBaqaya,
    required String supplierName,
    required String note,
    required DateTime purchaseDate,
    String imagePath = '',
  }) async {
    final currentList = state.value;
    if (currentList == null) return;
    
    final existing = currentList.firstWhere((e) => e.id == id);
    final netWeight = weight - deduction;
    final totalAmount = netWeight * ratePerUnit;
    final baqaya = totalAmount - jama;
    final netBaqaya = baqaya + sabhaBaqaya;

    final updated = KhareedEntity(
      id: existing.id,
      businessId: existing.businessId,
      itemName: itemName,
      vehicleNumber: vehicleNumber,
      weight: weight,
      weightUnit: weightUnit,
      deduction: deduction,
      netWeight: netWeight,
      ratePerUnit: ratePerUnit,
      totalAmount: totalAmount,
      jama: jama,
      baqaya: baqaya,
      sabhaBaqaya: sabhaBaqaya,
      netBaqaya: netBaqaya,
      supplierName: supplierName,
      note: note,
      purchaseDate: purchaseDate,
      createdAt: existing.createdAt,
      isDeleted: existing.isDeleted,
      imagePath: imagePath.isEmpty ? existing.imagePath : imagePath,
    );

    await _ref.read(updateKhareedUseCaseProvider)(updated);
    await _loadAll();
  }

  Future<void> delete(String id) async {
    await _ref.read(deleteKhareedUseCaseProvider)(id);
    await _loadAll();
  }
}

final khareedProvider = StateNotifierProvider<KhareedNotifier, AsyncValue<List<KhareedEntity>>>((ref) {
  final activeId = ref.watch(activeBusinessIdProvider);
  return KhareedNotifier(ref, activeId!);
});

final totalKhareedAmountProvider = Provider<double>((ref) {
  final list = ref.watch(khareedProvider).value ?? [];
  final now = DateTime.now();
  return list
      .where((r) => r.purchaseDate.year == now.year && r.purchaseDate.month == now.month)
      .fold(0.0, (sum, r) => sum + r.totalAmount);
});

final totalJamaProvider = Provider<double>((ref) {
  final list = ref.watch(khareedProvider).value ?? [];
  final now = DateTime.now();
  return list
      .where((r) => r.purchaseDate.year == now.year && r.purchaseDate.month == now.month)
      .fold(0.0, (sum, r) => sum + r.jama);
});

final totalBaqayaProvider = Provider<double>((ref) {
  final list = ref.watch(khareedProvider).value ?? [];
  final now = DateTime.now();
  return list
      .where((r) => r.purchaseDate.year == now.year && r.purchaseDate.month == now.month)
      .fold(0.0, (sum, r) => sum + r.netBaqaya);
});

final khareedCountProvider = Provider<int>((ref) {
  final list = ref.watch(khareedProvider).value ?? [];
  final now = DateTime.now();
  return list.where((r) => r.purchaseDate.year == now.year && r.purchaseDate.month == now.month).length;
});
