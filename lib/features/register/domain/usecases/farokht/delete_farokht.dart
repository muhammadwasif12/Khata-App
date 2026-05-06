import '../../repositories/farokht_repository.dart';

class DeleteFarokht {
  final FarokhtRepository repository;

  DeleteFarokht(this.repository);

  Future<void> call(String id) {
    return repository.delete(id);
  }
}
