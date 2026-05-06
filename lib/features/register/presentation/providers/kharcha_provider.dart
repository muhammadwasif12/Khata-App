import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/kharcha_model.dart';
import '../../data/repositories/kharcha_repository_impl.dart';
import '../../domain/entities/kharcha_entity.dart';
import '../../domain/usecases/kharcha/add_kharcha.dart';
import '../../domain/usecases/kharcha/delete_kharcha.dart';
import '../../domain/usecases/kharcha/get_all_kharcha.dart';
import '../../domain/usecases/kharcha/update_kharcha.dart';
import '../../../business/presentation/providers/business_provider.dart';

final kharchaBoxProvider = Provider<Box<KharchaModel>>((ref) {
  return Hive.box<KharchaModel>('kharcha');
});

final kharchaRepositoryProvider = Provider((ref) {
  return KharchaRepositoryImpl(ref.read(kharchaBoxProvider));
});

final getAllKharchaUseCaseProvider = Provider((ref) {
  return GetAllKharcha(ref.read(kharchaRepositoryProvider));
});
final addKharchaUseCaseProvider = Provider((ref) {
  return AddKharcha(ref.read(kharchaRepositoryProvider));
});
final updateKharchaUseCaseProvider = Provider((ref) {
  return UpdateKharcha(ref.read(kharchaRepositoryProvider));
});
final deleteKharchaUseCaseProvider = Provider((ref) {
  return DeleteKharcha(ref.read(kharchaRepositoryProvider));
});

class KharchaNotifier extends StateNotifier<AsyncValue<List<KharchaEntity>>> {
  final Ref _ref;
  final String _businessId;

  KharchaNotifier(this._ref, this._businessId) : super(const AsyncValue.loading()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final getUseCase = _ref.read(getAllKharchaUseCaseProvider);
      final records = await getUseCase(_businessId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add({
    required String category,
    required String customCategory,
    required double amount,
    required String note,
    required String paidTo,
    required String vehicleNumber,
    required String driverName,
    required DateTime expenseDate,
    String imagePath = '',
  }) async {
    final entry = KharchaEntity(
      id: const Uuid().v4(),
      businessId: _businessId,
      category: category,
      customCategory: customCategory,
      amount: amount,
      note: note,
      paidTo: paidTo,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      isDeleted: false,
      imagePath: imagePath,
    );

    await _ref.read(addKharchaUseCaseProvider)(entry);
    await _loadAll();
  }

  Future<void> update({
    required String id,
    required String category,
    required String customCategory,
    required double amount,
    required String note,
    required String paidTo,
    required String vehicleNumber,
    required String driverName,
    required DateTime expenseDate,
    String imagePath = '',
  }) async {
    final currentList = state.value;
    if (currentList == null) return;
    
    final existing = currentList.firstWhere((e) => e.id == id);

    final updated = KharchaEntity(
      id: existing.id,
      businessId: existing.businessId,
      category: category,
      customCategory: customCategory,
      amount: amount,
      note: note,
      paidTo: paidTo,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
      expenseDate: expenseDate,
      createdAt: existing.createdAt,
      isDeleted: existing.isDeleted,
      imagePath: imagePath.isEmpty ? existing.imagePath : imagePath,
    );

    await _ref.read(updateKharchaUseCaseProvider)(updated);
    await _loadAll();
  }

  Future<void> delete(String id) async {
    await _ref.read(deleteKharchaUseCaseProvider)(id);
    await _loadAll();
  }
}

final kharchaProvider = StateNotifierProvider<KharchaNotifier, AsyncValue<List<KharchaEntity>>>((ref) {
  final activeId = ref.watch(activeBusinessIdProvider);
  return KharchaNotifier(ref, activeId!);
});

final totalKharchaProvider = Provider<double>((ref) {
  final list = ref.watch(kharchaProvider).value ?? [];
  final now = DateTime.now();
  return list
      .where((r) => r.expenseDate.year == now.year && r.expenseDate.month == now.month)
      .fold(0.0, (sum, r) => sum + r.amount);
});

final kharchaCountProvider = Provider<int>((ref) {
  final list = ref.watch(kharchaProvider).value ?? [];
  final now = DateTime.now();
  return list.where((r) => r.expenseDate.year == now.year && r.expenseDate.month == now.month).length;
});
