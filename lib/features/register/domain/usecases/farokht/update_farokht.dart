import '../../entities/farokht_entity.dart';
import '../../repositories/farokht_repository.dart';

class UpdateFarokht {
  final FarokhtRepository repository;

  UpdateFarokht(this.repository);

  Future<void> call(FarokhtEntity entity) {
    return repository.update(entity);
  }
}
