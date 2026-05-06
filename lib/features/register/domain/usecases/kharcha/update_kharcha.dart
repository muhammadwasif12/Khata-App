import '../../entities/kharcha_entity.dart';
import '../../repositories/kharcha_repository.dart';

class UpdateKharcha {
  final KharchaRepository repository;

  UpdateKharcha(this.repository);

  Future<void> call(KharchaEntity entity) {
    return repository.update(entity);
  }
}
