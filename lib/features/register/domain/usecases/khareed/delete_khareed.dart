import '../../repositories/khareed_repository.dart';

class DeleteKhareed {
  final KhareedRepository repository;

  DeleteKhareed(this.repository);

  Future<void> call(String id) {
    return repository.delete(id);
  }
}
