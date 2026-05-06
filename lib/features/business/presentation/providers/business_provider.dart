import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepositoryImpl(),
);

final businessesProvider =
    StateNotifierProvider<BusinessNotifier, AsyncValue<List<BusinessEntity>>>((
      ref,
    ) {
      return BusinessNotifier(ref.watch(businessRepositoryProvider));
    });

final activeBusinessIdProvider = StateProvider<String?>((ref) => null);

class BusinessNotifier extends StateNotifier<AsyncValue<List<BusinessEntity>>> {
  final BusinessRepository _repository;
  final _uuid = const Uuid();

  BusinessNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBusinesses();
  }

  Future<void> loadBusinesses() async {
    state = const AsyncValue.loading();
    try {
      final businesses = await _repository.getAllBusinesses();
      state = AsyncValue.data(businesses);
      if (businesses.isNotEmpty) {
        final activeId = Hive.box(
          AppConstants.settingsBox,
        ).get(AppConstants.keyActiveBiz);
        if (activeId == null || !businesses.any((b) => b.id == activeId)) {
          await setActiveBusinessId(businesses.first.id);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBusiness({
    required String name,
    required String type,
    String ownerName = '',
    String phone = '',
    String address = '',
    String currency = 'PKR',
  }) async {
    final business = BusinessEntity(
      id: _uuid.v4(),
      name: name,
      type: type,
      ownerName: ownerName,
      phone: phone,
      address: address,
      currency: currency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.createBusiness(business);
    await loadBusinesses();
    await setActiveBusinessId(business.id);
  }

  Future<void> updateBusiness({
    required String id,
    required String name,
    required String type,
    String ownerName = '',
    String phone = '',
    String address = '',
    String currency = 'PKR',
  }) async {
    final existing = await _repository.getBusinessById(id);
    if (existing != null) {
      final updated = BusinessEntity(
        id: existing.id,
        name: name,
        type: type,
        ownerName: ownerName,
        phone: phone,
        address: address,
        currency: currency,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repository.updateBusiness(updated);
      await loadBusinesses();
    }
  }

  Future<void> deleteBusiness(String id) async {
    await _repository.deleteBusiness(id);
    await loadBusinesses();
  }

  Future<void> setActiveBusinessId(String id) async {
    await Hive.box(AppConstants.settingsBox).put(AppConstants.keyActiveBiz, id);
  }

  String? getActiveBusinessId() {
    return Hive.box(AppConstants.settingsBox).get(AppConstants.keyActiveBiz);
  }
}
