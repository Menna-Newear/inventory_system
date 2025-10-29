// ✅ presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/stock_management_service.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../domain/entities/user.dart';
import '../users/users_management_page.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/analytics_tab.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    InventoryRefreshNotifier().addListener(_refreshInventory);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderBloc>().add(LoadOrders());
      context.read<InventoryBloc>().add(LoadInventoryItems());
    });
  }

  @override
  void dispose() {
    InventoryRefreshNotifier().removeListener(_refreshInventory);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshInventory() {
    if (mounted) {
      context.read<InventoryBloc>().add(LoadInventoryItems());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        User? currentUser;
        if (authState is Authenticated) {
          currentUser = authState.user;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Inventory Management System',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            // ✅ Add actions menu
            actions: [
              // User Management Button (only for admins/managers)
              if (currentUser?.hasPermission(Permission.userView) ?? false)
                IconButton(
                  icon: Icon(Icons.people),
                  tooltip: 'User Management',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UsersManagementPage(),
                      ),
                    );
                  },
                ),

              // User Profile Menu
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    currentUser?.name[0].toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                tooltip: 'Account',
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  } else if (value == 'profile') {
                    _showProfileDialog(context, currentUser!);
                  }
                },
                itemBuilder: (context) => [
                  // User Info Header
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.name ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Chip(
                          label: Text(
                            currentUser?.role.displayName ?? 'User',
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getRoleColor(currentUser?.role),
                          labelStyle: TextStyle(color: Colors.white),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),

                  // Profile
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 12),
                        Text('My Profile'),
                      ],
                    ),
                  ),

                  // Logout
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.inventory_2), text: 'Inventory'),
                Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Orders'),
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              InventoryTab(),
              OrdersTab(),
              AnalyticsTab(),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Text('My Profile'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Name', user.name),
            SizedBox(height: 12),
            _buildProfileRow('Email', user.email),
            SizedBox(height: 12),
            _buildProfileRow('Role', user.role.displayName),
            SizedBox(height: 12),
            _buildProfileRow(
              'Account Created',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
            if (user.lastLogin != null) ...[
              SizedBox(height: 12),
              _buildProfileRow(
                'Last Login',
                '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year} ${user.lastLogin!.hour}:${user.lastLogin!.minute.toString().padLeft(2, '0')}',
              ),
            ],
            SizedBox(height: 16),
            Text(
              'Permissions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.permissions.map((perm) {
                return Chip(
                  label: Text(perm.displayName, style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.blue),
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.staff:
        return Colors.green;
      case UserRole.viewer:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
