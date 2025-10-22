// domain/usecases/add_serial_usecase.dart - FIXED
import 'package:dartz/dartz.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class AddSerialNumbers implements UseCase<List<SerialNumber>, AddSerialNumbersParams> {
  final InventoryRepository repository;

  AddSerialNumbers(this.repository);

  @override
  Future<Either<Failure, List<SerialNumber>>> call(AddSerialNumbersParams params) async {
    // ✅ FIXED: Just return the repository result directly
    return await repository.addSerialNumbers(params.itemId, params.serialNumbers);
  }
}

class AddSerialNumbersParams {
  final String itemId;
  final List<SerialNumber> serialNumbers;

  AddSerialNumbersParams({required this.itemId, required this.serialNumbers});
}
