// ✅ presentation/blocs/order/order_state.dart (WITH REFRESH SINGLE ORDER SUPPORT)
import 'package:equatable/equatable.dart';
import '../../../domain/entities/order.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  final List<Order>? filteredOrders;
  final String? searchQuery;
  final Map<String, dynamic>? appliedFilters;

  const OrderLoaded({
    required this.orders,
    this.filteredOrders,
    this.searchQuery,
    this.appliedFilters,
  });

  // ==================== DISPLAY & COMPUTED PROPERTIES ====================

  List<Order> get displayOrders => filteredOrders ?? orders;

  int get totalOrders => orders.length;

  int get approvedOrders => orders.where((order) => order.status == OrderStatus.approved).length;

  int get pendingOrders => orders.where((order) =>
  order.status == OrderStatus.draft || order.status == OrderStatus.pending).length;

  int get rejectedOrders => orders.where((order) => order.status == OrderStatus.rejected).length;

  double get totalRevenue => orders.fold(0.0, (sum, order) => sum + order.totalAmount);

  // Rental-specific stats
  int get activeRentals => orders.where((order) =>
  order.orderType == OrderType.rental && order.status == OrderStatus.approved).length;

  int get overdueRentals => orders.where((order) => order.isRentalOverdue).length;

  // ==================== STATE MANIPULATION METHODS ====================

  /// Updates a single order without refetching all orders
  OrderLoaded updateSingleOrder(Order updatedOrder) {
    // Update in main orders list
    final updatedOrders = orders.map((o) =>
    o.id == updatedOrder.id ? updatedOrder : o
    ).toList();

    // Also update in filtered orders if they exist
    final updatedFilteredOrders = filteredOrders?.map((o) =>
    o.id == updatedOrder.id ? updatedOrder : o
    ).toList();

    return copyWith(
      orders: updatedOrders,
      filteredOrders: updatedFilteredOrders,
    );
  }

  /// Adds a newly created order to the state
  OrderLoaded addSingleOrder(Order newOrder) {
    final updatedOrders = [newOrder, ...orders];

    // If filters are active and new order matches, add to filtered too
    final updatedFilteredOrders = filteredOrders != null
        ? [newOrder, ...filteredOrders!]
        : null;

    return copyWith(
      orders: updatedOrders,
      filteredOrders: updatedFilteredOrders,
    );
  }

  /// Removes a deleted order from the state
  OrderLoaded removeSingleOrder(String orderId) {
    final updatedOrders = orders.where((o) => o.id != orderId).toList();
    final updatedFilteredOrders = filteredOrders?.where((o) => o.id != orderId).toList();

    return copyWith(
      orders: updatedOrders,
      filteredOrders: updatedFilteredOrders,
    );
  }

  // ==================== COPY WITH ====================

  OrderLoaded copyWith({
    List<Order>? orders,
    List<Order>? filteredOrders,
    String? searchQuery,
    Map<String, dynamic>? appliedFilters,
    bool clearFilters = false,
  }) {
    return OrderLoaded(
      orders: orders ?? this.orders,
      filteredOrders: clearFilters ? null : (filteredOrders ?? this.filteredOrders),
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
      appliedFilters: clearFilters ? null : (appliedFilters ?? this.appliedFilters),
    );
  }

  @override
  List<Object> get props => [
    orders,
    filteredOrders ?? [],
    searchQuery ?? '',
    appliedFilters ?? {},
  ];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object> get props => [message];
}

// ✅ NEW: Operation result states (optional, for better UX)
class OrderOperationSuccess extends OrderState {
  final String message;
  final Order order;

  const OrderOperationSuccess({required this.message, required this.order});

  @override
  List<Object> get props => [message, order];
}

class OrderCreated extends OrderState {
  final Order order;

  const OrderCreated(this.order);

  @override
  List<Object> get props => [order];
}

class OrderUpdated extends OrderState {
  final Order order;

  const OrderUpdated(this.order);

  @override
  List<Object> get props => [order];
}

class OrderDeleted extends OrderState {
  final String orderId;

  const OrderDeleted(this.orderId);

  @override
  List<Object> get props => [orderId];
}
