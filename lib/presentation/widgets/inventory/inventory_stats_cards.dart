// presentation/widgets/inventory/inventory_stats_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/inventory/inventory_bloc.dart';

class InventoryStatsCards extends StatelessWidget {
  final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');
  final NumberFormat numberFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Total Items',
                    value: numberFormat.format(state.totalItems),
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Low Stock Items',
                    value: numberFormat.format(state.lowStockCount),
                    icon: Icons.warning,
                    color: state.lowStockCount > 0 ? Colors.red : Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Total Value',
                    value: currencyFormat.format(state.totalValue),
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Categories',
                    value: _getCategoriesCount(state.items).toString(),
                    icon: Icons.category,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox(height: 120);
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                Spacer(),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCategoriesCount(List items) {
    final categories = items.map((item) => item.categoryId).toSet();
    return categories.length;
  }
}
