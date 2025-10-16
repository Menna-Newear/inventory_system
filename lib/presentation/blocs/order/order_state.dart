// ✅ presentation/blocs/order/order_state.dart (ADD COMPUTED PROPERTIES)
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

  List<Order> get displayOrders => filteredOrders ?? orders;

  // ✅ NEW: Computed properties for dashboard
  int get totalOrders => orders.length;

  int get approvedOrders => orders.where((order) => order.status == OrderStatus.approved).length;

  int get pendingOrders => orders.where((order) =>
  order.status == OrderStatus.draft || order.status == OrderStatus.pending).length;

  int get rejectedOrders => orders.where((order) => order.status == OrderStatus.rejected).length;

  double get totalRevenue => orders.fold(0.0, (sum, order) => sum + order.totalAmount);

  // ✅ Rental-specific stats
  int get activeRentals => orders.where((order) =>
  order.orderType == OrderType.rental && order.status == OrderStatus.approved).length;

  int get overdueRentals => orders.where((order) => order.isRentalOverdue).length;

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
