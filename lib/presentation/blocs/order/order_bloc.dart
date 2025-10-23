// ✅ presentation/blocs/order/order_bloc.dart (COMPLETE WITH DEBUG)
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_orders.dart';
import '../../../domain/usecases/create_order.dart';
import '../../../domain/usecases/update_order.dart';
import '../../../domain/usecases/delete_order.dart';
import '../../../domain/usecases/approve_order.dart';
import '../../../domain/usecases/reject_order.dart';
import '../../../domain/usecases/search_orders.dart';
import '../../../domain/usecases/filter_orders.dart';
import '../../../data/repositories/order_repository_impl.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrders getOrders;
  final CreateOrder createOrder;
  final UpdateOrder updateOrder;
  final DeleteOrder deleteOrder;
  final ApproveOrder approveOrder;
  final RejectOrder rejectOrder;
  final SearchOrders searchOrders;
  final FilterOrders filterOrders;
  final OrderRepositoryImpl orderRepository;

  OrderBloc({
    required this.getOrders,
    required this.createOrder,
    required this.updateOrder,
    required this.deleteOrder,
    required this.approveOrder,
    required this.rejectOrder,
    required this.searchOrders,
    required this.filterOrders,
    required this.orderRepository,
  }) : super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CreateOrderEvent>(_onCreateOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
    on<DeleteOrderEvent>(_onDeleteOrder);
    on<ApproveOrderEvent>(_onApproveOrder);
    on<RejectOrderEvent>(_onRejectOrder);
    on<SearchOrdersEvent>(_onSearchOrders);
    on<FilterOrdersEvent>(_onFilterOrders);
    on<ClearOrderFilters>(_onClearFilters);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<ReturnRentalEvent>(_onReturnRental);
    on<RefreshSingleOrder>(_onRefreshSingleOrder);

  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Loading orders...');
    emit(OrderLoading());

    final result = await getOrders();
    result.fold(
          (failure) {
        print('❌ ORDER BLOC: Failed to load orders: ${failure.message}');
        emit(OrderError(failure.message));
      },
          (orders) {
        print('✅ ORDER BLOC: Loaded ${orders.length} orders');
        emit(OrderLoaded(orders: orders));
      },
    );
  }

  Future<void> _onCreateOrder(CreateOrderEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Creating order...');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final result = await createOrder(event.order);
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to create order: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (order) {
          print('✅ ORDER BLOC: Order created successfully: ${order.orderNumber}');
          final updatedOrders = [...currentState.orders, order];
          emit(currentState.copyWith(orders: updatedOrders));
        },
      );
    }
  }

  Future<void> _onUpdateOrder(UpdateOrderEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Updating order ${event.order.orderNumber}...');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final result = await updateOrder(event.order);
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to update order: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (order) {
          print('✅ ORDER BLOC: Order updated successfully: ${order.orderNumber}');
          final updatedOrders = currentState.orders
              .map((o) => o.id == order.id ? order : o)
              .toList();
          emit(currentState.copyWith(orders: updatedOrders));
        },
      );
    }
  }

  Future<void> _onDeleteOrder(DeleteOrderEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Deleting order ${event.orderId}...');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final result = await deleteOrder(event.orderId);
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to delete order: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (_) {
          print('✅ ORDER BLOC: Order deleted successfully');
          final updatedOrders = currentState.orders
              .where((o) => o.id != event.orderId)
              .toList();
          emit(currentState.copyWith(orders: updatedOrders));
        },
      );
    }
  }

  Future<void> _onApproveOrder(ApproveOrderEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Approving order ${event.orderId}...');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final result = await approveOrder(
        orderId: event.orderId,
        approvedBy: event.approvedBy,
        notes: event.notes,
      );
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to approve order: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (order) {
          print('✅ ORDER BLOC: Order approved successfully: ${order.orderNumber}');
          final updatedOrders = currentState.orders
              .map((o) => o.id == order.id ? order : o)
              .toList();
          emit(currentState.copyWith(orders: updatedOrders));
        },
      );
    }
  }

  Future<void> _onRejectOrder(RejectOrderEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Rejecting order ${event.orderId}...');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final result = await rejectOrder(
        orderId: event.orderId,
        rejectedBy: event.rejectedBy,
        reason: event.reason,
      );
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to reject order: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (order) {
          print('✅ ORDER BLOC: Order rejected successfully: ${order.orderNumber}');
          final updatedOrders = currentState.orders
              .map((o) => o.id == order.id ? order : o)
              .toList();
          emit(currentState.copyWith(orders: updatedOrders));
        },
      );
    }
  }

  Future<void> _onSearchOrders(SearchOrdersEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Searching orders with query: "${event.query}"');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      if (event.query.isEmpty) {
        print('🔍 ORDER BLOC: Clearing search - showing all orders');
        emit(currentState.copyWith(filteredOrders: null, searchQuery: null));
        return;
      }

      final result = await searchOrders(event.query);
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to search orders: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (orders) {
          print('✅ ORDER BLOC: Search found ${orders.length} orders');
          emit(currentState.copyWith(
            filteredOrders: orders,
            searchQuery: event.query,
          ));
        },
      );
    }
  }

  Future<void> _onFilterOrders(FilterOrdersEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Filtering orders with ${event.filters.length} filters');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      final result = await filterOrders(event.filters);
      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to filter orders: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (orders) {
          print('✅ ORDER BLOC: Filter found ${orders.length} orders');
          emit(currentState.copyWith(
            filteredOrders: orders,
            appliedFilters: event.filters,
          ));
        },
      );
    }
  }

  Future<void> _onClearFilters(ClearOrderFilters event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: Clearing all filters');

    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      emit(currentState.copyWith(clearFilters: true));
    }
  }

  // ✅ MAIN STOCK MANAGEMENT EVENT HANDLER
  Future<void> _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: ===== STARTING ORDER STATUS UPDATE =====');
    print('🔍 ORDER BLOC: Event received - Order ID: ${event.orderId}');
    print('🔍 ORDER BLOC: New Status: ${event.newStatus}');

    if (state is! OrderLoaded) {
      print('❌ ORDER BLOC: State is not OrderLoaded, cannot process');
      return;
    }

    final currentState = state as OrderLoaded;

    try {
      final oldOrder = currentState.orders.firstWhere((o) => o.id == event.orderId);

      print('🔍 ORDER BLOC: Found order: ${oldOrder.orderNumber}');
      print('🔍 ORDER BLOC: Order type: ${oldOrder.orderType.displayName}');
      print('🔍 ORDER BLOC: Current status: ${oldOrder.status}');
      print('🔍 ORDER BLOC: Target status: ${event.newStatus}');
      print('🔍 ORDER BLOC: Items count: ${oldOrder.items.length}');

      // Log items details
      for (int i = 0; i < oldOrder.items.length; i++) {
        final item = oldOrder.items[i];
        print('🔍 ORDER BLOC: Item ${i + 1}: ${item.itemName} (ID: ${item.itemId}, Qty: ${item.quantity})');
      }

      emit(OrderLoading());
      print('🔍 ORDER BLOC: Emitted OrderLoading state');

      print('🔍 ORDER BLOC: Calling orderRepository.updateOrderWithStock...');
      final result = await orderRepository.updateOrderWithStock(oldOrder, event.newStatus);

      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Update failed with error: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (updatedOrder) {
          print('✅ ORDER BLOC: Update successful!');
          print('✅ ORDER BLOC: Updated order status: ${updatedOrder.status}');

          final updatedOrders = currentState.orders
              .map((o) => o.id == updatedOrder.id ? updatedOrder : o)
              .toList();

          print('🔍 ORDER BLOC: Emitting OrderLoaded with updated orders');
          emit(OrderLoaded(orders: updatedOrders));

          print('✅ ORDER BLOC: ===== ORDER STATUS UPDATE COMPLETE =====');
        },
      );
    } catch (e) {
      print('❌ ORDER BLOC: Exception during status update: $e');
      print('❌ ORDER BLOC: Exception type: ${e.runtimeType}');
      if (e is StateError) {
        print('❌ ORDER BLOC: Order with ID ${event.orderId} not found in current orders');
        emit(OrderError('Order not found'));
      } else {
        emit(OrderError('Failed to update order status: $e'));
      }
    }
  }

  // ✅ RENTAL RETURN EVENT HANDLER
  Future<void> _onReturnRental(ReturnRentalEvent event, Emitter<OrderState> emit) async {
    print('🔍 ORDER BLOC: ===== STARTING RENTAL RETURN =====');
    print('🔍 ORDER BLOC: Rental ID: ${event.orderId}');

    if (state is! OrderLoaded) {
      print('❌ ORDER BLOC: State is not OrderLoaded, cannot process');
      return;
    }

    final currentState = state as OrderLoaded;
    emit(OrderLoading());

    try {
      final oldOrder = currentState.orders.firstWhere((o) => o.id == event.orderId);
      print('🔍 ORDER BLOC: Found rental order: ${oldOrder.orderNumber}');
      print('🔍 ORDER BLOC: Order type: ${oldOrder.orderType.displayName}');
      print('🔍 ORDER BLOC: Current status: ${oldOrder.status}');

      if (!oldOrder.isRental) {
        print('❌ ORDER BLOC: Order is not a rental order');
        emit(OrderError('This is not a rental order'));
        return;
      }

      print('🔍 ORDER BLOC: Calling orderRepository.returnRental...');
      final result = await orderRepository.returnRental(event.orderId);

      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Rental return failed: ${failure.message}');
          emit(OrderError(failure.message));
        },
            (updatedOrder) {
          print('✅ ORDER BLOC: Rental return successful!');
          print('✅ ORDER BLOC: Updated order status: ${updatedOrder.status}');

          final updatedOrders = currentState.orders
              .map((o) => o.id == updatedOrder.id ? updatedOrder : o)
              .toList();

          emit(OrderLoaded(orders: updatedOrders));
          print('✅ ORDER BLOC: ===== RENTAL RETURN COMPLETE =====');
        },
      );
    } catch (e) {
      print('❌ ORDER BLOC: Exception during rental return: $e');
      if (e is StateError) {
        print('❌ ORDER BLOC: Rental with ID ${event.orderId} not found');
        emit(OrderError('Rental order not found'));
      } else {
        emit(OrderError('Failed to return rental: $e'));
      }
    }
  }

  Future<void> _onRefreshSingleOrder(
      RefreshSingleOrder event,
      Emitter<OrderState> emit,
      ) async {
    final currentState = state;

    if (currentState is! OrderLoaded) {
      print('⚠️ ORDER BLOC: Not in loaded state, triggering full reload');
      add(LoadOrders());
      return;
    }

    print('🔄 ORDER BLOC: Refreshing single order: ${event.orderId}');

    try {
      // Get the updated order from the repository
      final result = await orderRepository.getOrderById(event.orderId);

      result.fold(
            (failure) {
          print('❌ ORDER BLOC: Failed to refresh order - ${failure.message}');
          // Don't emit error, just keep current state
        },
            (updatedOrder) {
          print('✅ ORDER BLOC: Order refreshed successfully');
          final newState = currentState.updateSingleOrder(updatedOrder);
          emit(newState);
          print('✅ ORDER BLOC: Single order updated in state');
        },
      );
    } catch (e) {
      print('❌ ORDER BLOC: Exception refreshing order: $e');
      // Don't emit error, just keep current state
    }
  }

}
