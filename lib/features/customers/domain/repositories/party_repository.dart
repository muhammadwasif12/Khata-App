import '../entities/party_entity.dart';

abstract class PartyRepository {
  Future<List<PartyEntity>> getPartiesByBusiness(
    String businessId, {
    PartyType? partyType,
  });
  Future<PartyEntity?> getPartyById(String id);
  Future<void> createParty(PartyEntity party);
  Future<void> updateParty(PartyEntity party);
  Future<void> deleteParty(String id);
}
