import '../entities/khareed_entity.dart';

abstract class KhareedRepository {
  Future<List<KhareedEntity>> getAllByBusiness(String businessId, {DateTime? from, DateTime? to});
  Future<KhareedEntity?> getById(String id);
  Future<void> create(KhareedEntity entity);
  Future<void> update(KhareedEntity entity);
  Future<void> delete(String id);
}
