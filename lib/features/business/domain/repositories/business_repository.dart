import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<List<BusinessEntity>> getAllBusinesses();
  Future<BusinessEntity?> getBusinessById(String id);
  Future<void> createBusiness(BusinessEntity business);
  Future<void> updateBusiness(BusinessEntity business);
  Future<void> deleteBusiness(String id);
}
