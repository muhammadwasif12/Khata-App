import '../../entities/khareed_entity.dart';
import '../../repositories/khareed_repository.dart';

class GetAllKhareed {
  final KhareedRepository repository;

  GetAllKhareed(this.repository);

  Future<List<KhareedEntity>> call(String businessId, {DateTime? from, DateTime? to}) {
    return repository.getAllByBusiness(businessId, from: from, to: to);
  }
}
