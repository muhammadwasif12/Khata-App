import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../data/repositories/party_repository_impl.dart';
import '../../domain/entities/party_entity.dart';
import '../../domain/repositories/party_repository.dart';

final partyRepositoryProvider = Provider<PartyRepository>(
  (ref) => PartyRepositoryImpl(),
);

final customersProvider =
    StateNotifierProvider<PartyNotifier, AsyncValue<List<PartyEntity>>>((ref) {
      final businessId = ref.watch(activeBusinessIdProvider);
      return PartyNotifier(
        ref.watch(partyRepositoryProvider),
        businessId,
        PartyType.customer,
      );
    });

final suppliersProvider =
    StateNotifierProvider<PartyNotifier, AsyncValue<List<PartyEntity>>>((ref) {
      final businessId = ref.watch(activeBusinessIdProvider);
      return PartyNotifier(
        ref.watch(partyRepositoryProvider),
        businessId,
        PartyType.supplier,
      );
    });

class PartyNotifier extends StateNotifier<AsyncValue<List<PartyEntity>>> {
  final PartyRepository _repository;
  final String? _businessId;
  final PartyType _partyType;
  final _uuid = const Uuid();

  PartyNotifier(this._repository, this._businessId, this._partyType)
    : super(const AsyncValue.loading()) {
    if (_businessId != null) {
      loadParties();
    }
  }

  Future<void> loadParties() async {
    if (_businessId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final parties = await _repository.getPartiesByBusiness(
        _businessId!,
        partyType: _partyType,
      );
      state = AsyncValue.data(parties);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addParty({
    required String name,
    String phone = '',
    double openingBalance = 0,
    bool isOpeningCredit = true,
  }) async {
    if (_businessId == null) return;
    final party = PartyEntity(
      id: _uuid.v4(),
      businessId: _businessId!,
      name: name,
      phone: phone,
      openingBalance: openingBalance,
      isOpeningCredit: isOpeningCredit,
      partyType: _partyType,
      createdAt: DateTime.now(),
    );
    await _repository.createParty(party);
    await loadParties();
  }

  Future<void> updateParty(String id, String name, String phone) async {
    final existing = await _repository.getPartyById(id);
    if (existing != null) {
      final updated = PartyEntity(
        id: existing.id,
        businessId: existing.businessId,
        name: name,
        phone: phone,
        openingBalance: existing.openingBalance,
        isOpeningCredit: existing.isOpeningCredit,
        partyType: existing.partyType,
        createdAt: existing.createdAt,
      );
      await _repository.updateParty(updated);
      await loadParties();
    }
  }

  Future<void> deleteParty(String id) async {
    await _repository.deleteParty(id);
    await loadParties();
  }
}
