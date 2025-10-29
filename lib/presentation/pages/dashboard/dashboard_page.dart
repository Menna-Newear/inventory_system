// ✅ presentation/pages/dashboard/dashboard_page.dart (WITH LANGUAGE & THEME TOGGLE!)
import 'package:easy_localization/easy_localization.dart';
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
  ThemeMode _themeMode = ThemeMode.system; // ✅ Theme state

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
              'app_title'.tr(), // ✅ Translated
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              // User Management Button (only for admins/managers)
              if (currentUser?.hasPermission(Permission.userView) ?? false)
                IconButton(
                  icon: Icon(Icons.people),
                  tooltip: 'users.title'.tr(), // ✅ Translated
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
                  } else if (value == 'language') {
                    _showLanguageDialog(context);
                  } else if (value == 'theme') {
                    _showThemeDialog(context);
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

                  // ✅ Language Switcher
                  PopupMenuItem(
                    value: 'language',
                    child: Row(
                      children: [
                        Icon(Icons.language, size: 20),
                        SizedBox(width: 12),
                        Text('Language'),
                        Spacer(),
                        Text(
                          context.locale == Locale('en') ? '🇬🇧 EN' : '🇸🇦 AR',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Theme Toggle
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          _themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Theme'),
                        Spacer(),
                        Text(
                          _themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuDivider(),

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
                Tab(icon: Icon(Icons.inventory_2), text: 'navigation.inventory'.tr()),
                Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'navigation.orders'.tr()),
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

  // ✅ Language Switcher Dialog
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.language, color: Colors.blue),
            SizedBox(width: 8),
            Text('Choose Language'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text('English'),
              trailing: context.locale == Locale('en')
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(Locale('en'));
                Navigator.pop(dialogContext);
                setState(() {}); // Refresh UI
              },
            ),
            ListTile(
              leading: Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: Text('العربية (Arabic)'),
              trailing: context.locale == Locale('ar')
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(Locale('ar'));
                Navigator.pop(dialogContext);
                setState(() {}); // Refresh UI
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ Theme Switcher Dialog
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette, color: Colors.purple),
              SizedBox(width: 8),
              Text('Choose Theme'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('Light Mode'),
                subtitle: Text('Bright and clean'),
                secondary: Icon(Icons.light_mode, color: Colors.orange),
                value: ThemeMode.light,
                groupValue: _themeMode,
                onChanged: (value) {
                  setDialogState(() {
                    _themeMode = value!;
                  });
                  setState(() {});
                  // TODO: Update theme in main app (need ThemeBloc)
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark Mode'),
                subtitle: Text('Easy on the eyes'),
                secondary: Icon(Icons.dark_mode, color: Colors.indigo),
                value: ThemeMode.dark,
                groupValue: _themeMode,
                onChanged: (value) {
                  setDialogState(() {
                    _themeMode = value!;
                  });
                  setState(() {});
                  // TODO: Update theme in main app (need ThemeBloc)
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('System Default'),
                subtitle: Text('Follow system settings'),
                secondary: Icon(Icons.brightness_auto, color: Colors.grey),
                value: ThemeMode.system,
                groupValue: _themeMode,
                onChanged: (value) {
                  setDialogState(() {
                    _themeMode = value!;
                  });
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close'),
            ),
          ],
        ),
      ),
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
            child: Text('common.cancel'.tr()),
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
            child: Text('common.close'.tr()),
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
