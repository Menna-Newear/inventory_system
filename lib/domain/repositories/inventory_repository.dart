// domain/repositories/inventory_repository.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryItem>>> getAllInventoryItems();
  Future<Either<Failure, InventoryItem>> getInventoryItem(String id);
  Future<Either<Failure, InventoryItem>> createInventoryItem(InventoryItem item);
  Future<Either<Failure, InventoryItem>> updateInventoryItem(InventoryItem item);
  Future<Either<Failure, void>> deleteInventoryItem(String id);
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(String query);
  Future<Either<Failure, List<InventoryItem>>> filterInventoryItems(Map<String, dynamic> filters);
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems();
  Stream<List<InventoryItem>> watchInventoryItems();
}
