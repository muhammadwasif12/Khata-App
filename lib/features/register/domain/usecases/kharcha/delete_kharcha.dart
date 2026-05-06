import '../../repositories/kharcha_repository.dart';

class DeleteKharcha {
  final KharchaRepository repository;

  DeleteKharcha(this.repository);

  Future<void> call(String id) {
    return repository.delete(id);
  }
}
