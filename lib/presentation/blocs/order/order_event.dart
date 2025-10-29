// ✅ presentation/blocs/order/order_event.dart (WITH PERMISSIONS!)
import 'package:equatable/equatable.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/user.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

// ✅ Load orders
class LoadOrders extends OrderEvent {}

// ✅ Set current user for permission checks
class SetCurrentUser extends OrderEvent {
  final User user;

  const SetCurrentUser(this.user);

  @override
  List<Object?> get props => [user];
}

// ✅ Create order
class CreateOrderEvent extends OrderEvent {
  final Order order;

  const CreateOrderEvent(this.order);

  @override
  List<Object?> get props => [order];
}

// ✅ Update order
class UpdateOrderEvent extends OrderEvent {
  final Order order;

  const UpdateOrderEvent(this.order);

  @override
  List<Object?> get props => [order];
}

// ✅ Delete order
class DeleteOrderEvent extends OrderEvent {
  final String orderId;

  const DeleteOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// ✅ Approve order
class ApproveOrderEvent extends OrderEvent {
  final String orderId;
  final String approvedBy;
  final String? notes;

  const ApproveOrderEvent({
    required this.orderId,
    required this.approvedBy,
    this.notes,
  });

  @override
  List<Object?> get props => [orderId, approvedBy, notes];
}

// ✅ Reject order
class RejectOrderEvent extends OrderEvent {
  final String orderId;
  final String rejectedBy;
  final String reason;

  const RejectOrderEvent({
    required this.orderId,
    required this.rejectedBy,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, rejectedBy, reason];
}

// ✅ Search orders
class SearchOrdersEvent extends OrderEvent {
  final String query;

  const SearchOrdersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

// ✅ Filter orders
class FilterOrdersEvent extends OrderEvent {
  final Map<String, dynamic> filters;

  const FilterOrdersEvent(this.filters);

  @override
  List<Object?> get props => [filters];
}

// ✅ Clear filters
class ClearOrderFilters extends OrderEvent {}

// ✅ Update order status (with stock management)
class UpdateOrderStatusEvent extends OrderEvent {
  final String orderId;
  final OrderStatus newStatus;

  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [orderId, newStatus];
}

// ✅ Return rental
class ReturnRentalEvent extends OrderEvent {
  final String orderId;

  const ReturnRentalEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// ✅ Refresh single order
class RefreshSingleOrder extends OrderEvent {
  final String orderId;

  const RefreshSingleOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
