import '../../entities/khareed_entity.dart';
import '../../repositories/khareed_repository.dart';

class UpdateKhareed {
  final KhareedRepository repository;

  UpdateKhareed(this.repository);

  Future<void> call(KhareedEntity entry) async {
    await repository.update(entry);
  }
}
