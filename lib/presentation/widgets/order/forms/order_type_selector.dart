// ✅ presentation/widgets/order/forms/order_type_selector.dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/order.dart';

class OrderTypeSelector extends StatelessWidget {
  final OrderType selectedType;
  final Function(OrderType) onTypeChanged;

  const OrderTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Type *',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Row(
          children: OrderType.values.map((type) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: type == OrderType.sell ? 8 : 0),
                child: _OrderTypeCard(
                  type: type,
                  isSelected: selectedType == type,
                  onTap: () => onTypeChanged(type),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _OrderTypeCard extends StatelessWidget {
  final OrderType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? type.typeColor.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? type.typeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              type.icon,
              size: 40,
              color: isSelected ? type.typeColor : Colors.grey[600],
            ),
            SizedBox(height: 12),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? type.typeColor : Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              type.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
