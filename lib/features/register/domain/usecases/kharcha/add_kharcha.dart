import '../../entities/kharcha_entity.dart';
import '../../repositories/kharcha_repository.dart';

class AddKharcha {
  final KharchaRepository repository;

  AddKharcha(this.repository);

  Future<void> call(KharchaEntity entity) {
    return repository.create(entity);
  }
}
