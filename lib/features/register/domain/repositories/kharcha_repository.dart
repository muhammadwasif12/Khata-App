import '../entities/kharcha_entity.dart';

abstract class KharchaRepository {
  Future<List<KharchaEntity>> getAllByBusiness(String businessId, {DateTime? from, DateTime? to});
  Future<KharchaEntity?> getById(String id);
  Future<void> create(KharchaEntity entity);
  Future<void> update(KharchaEntity entity);
  Future<void> delete(String id);
}
