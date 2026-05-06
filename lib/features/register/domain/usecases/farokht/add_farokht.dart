import '../../entities/farokht_entity.dart';
import '../../repositories/farokht_repository.dart';

class AddFarokht {
  final FarokhtRepository repository;

  AddFarokht(this.repository);

  Future<void> call(FarokhtEntity entity) {
    return repository.create(entity);
  }
}
