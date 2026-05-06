import '../../entities/kharcha_entity.dart';
import '../../repositories/kharcha_repository.dart';

class GetAllKharcha {
  final KharchaRepository repository;

  GetAllKharcha(this.repository);

  Future<List<KharchaEntity>> call(String businessId, {DateTime? from, DateTime? to}) {
    return repository.getAllByBusiness(businessId, from: from, to: to);
  }
}
