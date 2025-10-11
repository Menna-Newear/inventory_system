// domain/usecases/update_serial_status.dart - FIXED
import 'package:dartz/dartz.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

class UpdateSerialStatus implements UseCase<SerialNumber, UpdateSerialStatusParams> {
  final InventoryRepository repository;

  UpdateSerialStatus(this.repository);

  @override
  Future<Either<Failure, SerialNumber>> call(UpdateSerialStatusParams params) async {
    // ✅ FIXED: Just return the repository result directly
    return await repository.updateSerialStatus(
      params.serialId,
      params.newStatus,
      notes: params.notes,
    );
  }
}

class UpdateSerialStatusParams {
  final String serialId;
  final SerialStatus newStatus;
  final String? notes;

  UpdateSerialStatusParams({
    required this.serialId,
    required this.newStatus,
    this.notes,
  });
}
