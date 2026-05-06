import '../../entities/farokht_entity.dart';
import '../../repositories/farokht_repository.dart';

class GetAllFarokht {
  final FarokhtRepository repository;

  GetAllFarokht(this.repository);

  Future<List<FarokhtEntity>> call(String businessId, {DateTime? from, DateTime? to}) {
    return repository.getAllByBusiness(businessId, from: from, to: to);
  }
}
