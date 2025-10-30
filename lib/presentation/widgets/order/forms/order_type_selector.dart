// ✅ presentation/widgets/order/forms/order_type_selector.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category,
                size: 20,
                color: theme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'order_type_selector.title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // ✅ Responsive layout
            if (constraints.maxWidth < 600) {
              // Mobile: Vertical layout
              return Column(
                children: OrderType.values
                    .map((type) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _OrderTypeCard(
                    type: type,
                    isSelected: selectedType == type,
                    onTap: () => onTypeChanged(type),
                    isDark: isDark,
                  ),
                ))
                    .toList(),
              );
            } else {
              // Desktop: Horizontal layout
              return Row(
                children: OrderType.values.map((type) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: type == OrderType.sell ? 12 : 0,
                      ),
                      child: _OrderTypeCard(
                        type: type,
                        isSelected: selectedType == type,
                        onTap: () => onTypeChanged(type),
                        isDark: isDark,
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }
}

class _OrderTypeCard extends StatefulWidget {
  final OrderType type;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _OrderTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_OrderTypeCard> createState() => _OrderTypeCardState();
}

class _OrderTypeCardState extends State<_OrderTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLocalizedName() {
    switch (widget.type) {
      case OrderType.sell:
        return 'order_type_selector.sell.name'.tr();
      case OrderType.rental:
        return 'order_type_selector.rental.name'.tr();
    }
  }

  String _getLocalizedDescription() {
    switch (widget.type) {
      case OrderType.sell:
        return 'order_type_selector.sell.description'.tr();
      case OrderType.rental:
        return 'order_type_selector.rental.description'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                colors: [
                  widget.type.typeColor.withOpacity(0.15),
                  widget.type.typeColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [
                  widget.isDark
                      ? Colors.grey[850]!
                      : Colors.grey[50]!,
                  widget.isDark
                      ? Colors.grey[850]!
                      : Colors.grey[50]!,
                ],
              ),
              border: Border.all(
                color: widget.isSelected
                    ? widget.type.typeColor
                    : (_isHovered
                    ? widget.type.typeColor.withOpacity(0.5)
                    : (widget.isDark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!)),
                width: widget.isSelected ? 3 : (_isHovered ? 2 : 1),
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: widget.isSelected || _isHovered
                  ? [
                BoxShadow(
                  color: widget.type.typeColor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.type.typeColor.withOpacity(0.2)
                        : (widget.isDark
                        ? Colors.grey[800]
                        : Colors.grey[100]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.type.icon,
                    size: 48,
                    color: widget.isSelected
                        ? widget.type.typeColor
                        : (widget.isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _getLocalizedName(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected
                        ? widget.type.typeColor
                        : (widget.isDark ? Colors.white : Colors.grey[800]),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getLocalizedDescription(),
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.isSelected) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.type.typeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
