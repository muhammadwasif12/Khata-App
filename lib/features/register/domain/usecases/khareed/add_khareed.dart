import '../../entities/khareed_entity.dart';
import '../../repositories/khareed_repository.dart';

class AddKhareed {
  final KhareedRepository repository;

  AddKhareed(this.repository);

  Future<void> call(KhareedEntity entry) async {
    await repository.create(entry);
  }
}
