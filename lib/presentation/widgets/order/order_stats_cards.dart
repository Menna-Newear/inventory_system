// ✅ presentation/widgets/order/order_stats_cards.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_state.dart';

class OrderStatsCards extends StatelessWidget {
  final bool showRentalStats;
  final EdgeInsetsGeometry? padding;

  const OrderStatsCards({
    Key? key,
    this.showRentalStats = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoaded) {
          return _buildStatsContent(state, theme, isDark);
        }
        return Center(
          child: Text('order_stats.no_data'.tr()),
        );
      },
    );
  }

  Widget _buildStatsContent(
      OrderLoaded state,
      ThemeData theme,
      bool isDark,
      ) {
    final stats = [
      StatItem(
        title: 'order_stats.total_orders'.tr(),
        value: state.totalOrders.toString(),
        icon: Icons.shopping_cart,
        color: Colors.blue,
      ),
      StatItem(
        title: 'order_stats.approved'.tr(),
        value: state.approvedOrders.toString(),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      StatItem(
        title: 'order_stats.pending'.tr(),
        value: state.pendingOrders.toString(),
        icon: Icons.pending,
        color: Colors.orange,
      ),
      StatItem(
        title: 'order_stats.revenue'.tr(),
        value: '\$${state.totalRevenue.toStringAsFixed(0)}',
        icon: Icons.attach_money,
        color: Colors.purple,
      ),
    ];

    // Optional rental stats
    final allStats = showRentalStats
        ? [
      ...stats,
      StatItem(
        title: 'order_stats.active_rentals'.tr(),
        value: state.activeRentals.toString(),
        icon: Icons.apartment,
        color: Colors.teal,
      ),
      StatItem(
        title: 'order_stats.overdue_rentals'.tr(),
        value: state.overdueRentals.toString(),
        icon: Icons.warning,
        color: Colors.red,
      ),
    ]
        : stats;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(
          allStats.length,
              (index) {
            final statItem = allStats[index];
            return Container(
              margin: EdgeInsets.only(right: index < allStats.length - 1 ? 12 : 0),
              child: _buildStatCard(
                statItem.title,
                statItem.value,
                statItem.icon,
                statItem.color,
                isDark,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      bool isDark,
      ) {
    return Container(
      padding: EdgeInsets.all(16),
      width: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.7,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Data class for organizing stat items
class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
