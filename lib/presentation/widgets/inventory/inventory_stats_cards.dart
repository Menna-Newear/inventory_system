// presentation/widgets/inventory/inventory_stats_cards.dart (ENHANCED & LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/inventory/inventory_bloc.dart';

class InventoryStatsCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          // ✅ Get currency symbol based on locale
          final locale = context.locale;
          final currencySymbol = _getCurrencySymbol(locale.languageCode);

          return Padding(
            padding: EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ✅ Responsive layout
                if (constraints.maxWidth < 800) {
                  // Mobile: 2 columns
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'inventory_stats.total_items'.tr(),
                              value: _formatNumber(state.totalItems),
                              icon: Icons.inventory,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'inventory_stats.low_stock_items'.tr(),
                              value: _formatNumber(state.lowStockCount),
                              icon: Icons.warning,
                              color: state.lowStockCount > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'inventory_stats.total_value'.tr(),
                              value: _formatCurrency(state.totalValue, currencySymbol),
                              icon: Icons.account_balance_wallet,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              title: 'inventory_stats.categories'.tr(),
                              value: _getCategoriesCount(state.items).toString(),
                              icon: Icons.category,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Desktop: 4 columns
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          title: 'inventory_stats.total_items'.tr(),
                          value: _formatNumber(state.totalItems),
                          icon: Icons.inventory,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          title: 'inventory_stats.low_stock_items'.tr(),
                          value: _formatNumber(state.lowStockCount),
                          icon: Icons.warning,
                          color: state.lowStockCount > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          title: 'inventory_stats.total_value'.tr(),
                          value: _formatCurrency(state.totalValue, currencySymbol),
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context: context,
                          title: 'inventory_stats.categories'.tr(),
                          value: _getCategoriesCount(state.items).toString(),
                          icon: Icons.category,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  );
                }
              },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? theme.cardColor : Colors.white,
              isDark ? theme.cardColor : color.withOpacity(0.02),
            ],
          ),
        ),
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
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                ],
              ),
              SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Get currency symbol based on locale
  String _getCurrencySymbol(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'ر.س'; // Saudi Riyal (or adjust for your region)
      case 'en':
      default:
        return 'ر.س';
    }
  }

  // ✅ Format currency with locale support
  String _formatCurrency(double value, String symbol) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(value)}';
  }

  // ✅ Format numbers with locale support
  String _formatNumber(int value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  // ✅ Count unique categories
  int _getCategoriesCount(List items) {
    final categories = items.map((item) => item.categoryId).toSet();
    return categories.length;
  }
}
