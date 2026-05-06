import '../entities/farokht_entity.dart';

abstract class FarokhtRepository {
  Future<List<FarokhtEntity>> getAllByBusiness(String businessId, {DateTime? from, DateTime? to});
  Future<FarokhtEntity?> getById(String id);
  Future<void> create(FarokhtEntity entity);
  Future<void> update(FarokhtEntity entity);
  Future<void> delete(String id);
}
