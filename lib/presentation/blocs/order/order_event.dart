// ✅ presentation/blocs/order/order_event.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/order.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object> get props => [];
}

class LoadOrders extends OrderEvent {}

class CreateOrderEvent extends OrderEvent {
  final Order order;

  const CreateOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}

class UpdateOrderEvent extends OrderEvent {
  final Order order;

  const UpdateOrderEvent(this.order);

  @override
  List<Object> get props => [order];
}

class DeleteOrderEvent extends OrderEvent {
  final String orderId;

  const DeleteOrderEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}

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
  List<Object> get props => [orderId, approvedBy];
}

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
  List<Object> get props => [orderId, rejectedBy, reason];
}

class SearchOrdersEvent extends OrderEvent {
  final String query;

  const SearchOrdersEvent(this.query);

  @override
  List<Object> get props => [query];
}

class FilterOrdersEvent extends OrderEvent {
  final Map<String, dynamic> filters;

  const FilterOrdersEvent(this.filters);

  @override
  List<Object> get props => [filters];
}

class ClearOrderFilters extends OrderEvent {}

// ✅ MISSING EVENTS - ADD THESE!
class UpdateOrderStatusEvent extends OrderEvent {
  final String orderId;
  final OrderStatus newStatus;

  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.newStatus,
  });

  @override
  List<Object> get props => [orderId, newStatus];
}

class ReturnRentalEvent extends OrderEvent {
  final String orderId;

  const ReturnRentalEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}
class RefreshSingleOrder extends OrderEvent {
  final String orderId;

  const RefreshSingleOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}
