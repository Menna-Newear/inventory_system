// ✅ data/repositories/order_repository_impl.dart (COMPLETE UPDATED VERSION)
import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../core/network/network_info.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';
import '../services/stock_management_service.dart' hide ValidationFailure;

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final StockManagementService stockManagementService;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.stockManagementService,
  });

  @override
  Future<Either<Failure, List<Order>>> getOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final orders = await remoteDataSource.getOrders();
        return Right(orders);
      } catch (e) {
        return Left(ServerFailure('Failed to fetch orders: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ✅ NEW: Update order with stock management
  Future<Either<Failure, Order>> updateOrderWithStock(Order order, OrderStatus newStatus) async {
    if (await networkInfo.isConnected) {
      try {
        final oldStatus = order.status;

        // ✅ 1. Validate stock if approving order
        if (newStatus == OrderStatus.approved &&
            (oldStatus == OrderStatus.draft || oldStatus == OrderStatus.pending)) {
          final stockValidation = await stockManagementService.validateStockAvailability(order);
          if (stockValidation.isLeft()) {
            return stockValidation.fold((l) => Left(l), (r) => throw Exception());
          }
        }

        // ✅ 2. Handle stock changes
        final stockUpdateResult = await stockManagementService.handleOrderStatusChange(
            order,
            oldStatus,
            newStatus
        );
        if (stockUpdateResult.isLeft()) {
          return stockUpdateResult.fold((l) => Left(l), (r) => throw Exception());
        }

        // ✅ 3. Update order status
        final updatedOrder = order.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );

        final orderModel = _orderToModel(updatedOrder);
        final result = await remoteDataSource.updateOrder(orderModel);

        print('✅ Order ${order.orderNumber} updated: $oldStatus → $newStatus');
        return Right(result);
      } catch (e) {
        return Left(ServerFailure('Failed to update order with stock: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(Order order) async {
    if (await networkInfo.isConnected) {
      try {
        final orderModel = OrderModel(
          id: order.id,
          orderNumber: order.orderNumber,
          status: order.status,
          orderType: order.orderType,
          items: order.items,
          customerName: order.customerName,
          customerEmail: order.customerEmail,
          customerPhone: order.customerPhone,
          shippingAddress: order.shippingAddress,
          notes: order.notes,
          totalAmount: order.totalAmount,
          rentalStartDate: order.rentalStartDate,
          rentalEndDate: order.rentalEndDate,
          rentalDurationDays: order.rentalDurationDays,
          dailyRate: order.dailyRate,
          securityDeposit: order.securityDeposit,
          approvedBy: order.approvedBy,
          approvedAt: order.approvedAt,
          rejectedBy: order.rejectedBy,
          rejectedAt: order.rejectedAt,
          rejectionReason: order.rejectionReason,
          createdBy: order.createdBy,
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
        );

        final createdOrder = await remoteDataSource.createOrder(orderModel);
        return Right(createdOrder);
      } catch (e) {
        return Left(ServerFailure('Failed to create order: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrder(Order order) async {
    if (await networkInfo.isConnected) {
      try {
        final orderModel = _orderToModel(order);
        final updatedOrder = await remoteDataSource.updateOrder(orderModel);
        return Right(updatedOrder);
      } catch (e) {
        return Left(ServerFailure('Failed to update order: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrder(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteOrder(id);
        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to delete order: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ✅ UPDATED: approveOrder with stock management
  @override
  Future<Either<Failure, Order>> approveOrder({
    required String orderId,
    required String approvedBy,
    String? notes,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get current order first
        final orderResult = await getOrderById(orderId);
        if (orderResult.isLeft()) {
          return orderResult.fold((l) => Left(l), (r) => throw Exception());
        }

        final order = orderResult.fold((l) => throw Exception(), (r) => r);

        // Use updateOrderWithStock for stock management
        final updatedOrder = order.copyWith(
          status: OrderStatus.approved,
          approvedBy: approvedBy,
          approvedAt: DateTime.now(),
        );

        return await updateOrderWithStock(updatedOrder, OrderStatus.approved);
      } catch (e) {
        return Left(ServerFailure('Failed to approve order: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ✅ UPDATED: rejectOrder with stock management
  @override
  Future<Either<Failure, Order>> rejectOrder({
    required String orderId,
    required String rejectedBy,
    required String reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get current order first
        final orderResult = await getOrderById(orderId);
        if (orderResult.isLeft()) {
          return orderResult.fold((l) => Left(l), (r) => throw Exception());
        }

        final order = orderResult.fold((l) => throw Exception(), (r) => r);

        // Use updateOrderWithStock for stock management
        final updatedOrder = order.copyWith(
          status: OrderStatus.rejected,
          rejectedBy: rejectedBy,
          rejectedAt: DateTime.now(),
          rejectionReason: reason,
        );

        return await updateOrderWithStock(updatedOrder, OrderStatus.rejected);
      } catch (e) {
        return Left(ServerFailure('Failed to reject order: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> searchOrders(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final orders = await remoteDataSource.searchOrders(query);
        return Right(orders);
      } catch (e) {
        return Left(ServerFailure('Failed to search orders: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> filterOrders(Map<String, dynamic> filters) async {
    if (await networkInfo.isConnected) {
      try {
        final orders = await remoteDataSource.filterOrders(filters);
        return Right(orders);
      } catch (e) {
        return Left(ServerFailure('Failed to filter orders: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ✅ NEW: Get active rentals
  Future<Either<Failure, List<Order>>> getActiveRentals() async {
    if (await networkInfo.isConnected) {
      try {
        final rentals = await remoteDataSource.getActiveRentals();
        return Right(rentals);
      } catch (e) {
        return Left(ServerFailure('Failed to get active rentals: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ✅ NEW: Get overdue rentals
  Future<Either<Failure, List<Order>>> getOverdueRentals() async {
    if (await networkInfo.isConnected) {
      try {
        final rentals = await remoteDataSource.getOverdueRentals();
        return Right(rentals);
      } catch (e) {
        return Left(ServerFailure('Failed to get overdue rentals: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ✅ UPDATED: Return rental with stock management
  Future<Either<Failure, Order>> returnRental(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        // Get current order first
        final orderResult = await getOrderById(orderId);
        if (orderResult.isLeft()) {
          return orderResult.fold((l) => Left(l), (r) => throw Exception());
        }

        final order = orderResult.fold((l) => throw Exception(), (r) => r);

        // Use updateOrderWithStock for stock management
        return await updateOrderWithStock(order, OrderStatus.returned);
      } catch (e) {
        return Left(ServerFailure('Failed to return rental: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  Future<Either<Failure, Order>> getOrderById(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        final order = await remoteDataSource.getOrderById(orderId);
        return Right(order);
      } catch (e) {
        return Left(ServerFailure('Failed to get order: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getOrderStats() async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getOrderStats();
        return Right(stats);
      } catch (e) {
        return Left(ServerFailure('Failed to get order statistics: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  OrderModel _orderToModel(Order order) {
    return OrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      orderType: order.orderType,
      items: order.items,
      customerName: order.customerName,
      customerEmail: order.customerEmail,
      customerPhone: order.customerPhone,
      shippingAddress: order.shippingAddress,
      notes: order.notes,
      totalAmount: order.totalAmount,
      rentalStartDate: order.rentalStartDate,
      rentalEndDate: order.rentalEndDate,
      rentalDurationDays: order.rentalDurationDays,
      dailyRate: order.dailyRate,
      securityDeposit: order.securityDeposit,
      approvedBy: order.approvedBy,
      approvedAt: order.approvedAt,
      rejectedBy: order.rejectedBy,
      rejectedAt: order.rejectedAt,
      rejectionReason: order.rejectionReason,
      createdBy: order.createdBy,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  // ✅ Business logic methods remain the same...
  Either<Failure, bool> validateRentalOrder(Order order) {
    if (!order.isRental) return Right(true);

    if (order.rentalStartDate == null) {
      return Left(ValidationFailure('Rental start date is required'));
    }

    if (order.rentalEndDate == null) {
      return Left(ValidationFailure('Rental end date is required'));
    }

    if (order.rentalEndDate!.isBefore(order.rentalStartDate!)) {
      return Left(ValidationFailure('Rental end date must be after start date'));
    }

    if (order.rentalStartDate!.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      return Left(ValidationFailure('Rental start date cannot be in the past'));
    }

    final duration = order.rentalEndDate!.difference(order.rentalStartDate!);
    if (duration.inDays < 1) {
      return Left(ValidationFailure('Minimum rental duration is 1 day'));
    }

    if (order.dailyRate == null || order.dailyRate! <= 0) {
      return Left(ValidationFailure('Daily rate must be greater than 0'));
    }

    return Right(true);
  }

  double calculateRentalTotal(Order order) {
    if (!order.isRental) return order.totalAmount;

    final days = order.calculatedRentalDays;
    final dailyRate = order.dailyRate ?? 0.0;
    final deposit = order.securityDeposit ?? 0.0;

    return (dailyRate * days) + deposit;
  }

  bool canReturnRental(Order order) {
    return order.isRental &&
        order.status == OrderStatus.approved &&
        order.rentalStartDate != null &&
        DateTime.now().isAfter(order.rentalStartDate!);
  }

  String getRentalStatusDescription(Order order) {
    if (!order.isRental) return order.status.displayName;

    if (order.isRentalActive) {
      return 'Active Rental';
    } else if (order.isRentalOverdue) {
      return 'Overdue Rental';
    } else if (order.status == OrderStatus.returned) {
      return 'Returned';
    } else if (order.rentalStartDate != null &&
        DateTime.now().isBefore(order.rentalStartDate!)) {
      return 'Scheduled Rental';
    }

    return order.statusDisplayText;
  }
}
