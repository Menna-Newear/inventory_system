// ✅ presentation/pages/dashboard/dashboard_page.dart (FULLY LOCALIZED!)
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
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../blocs/theme/theme_state.dart';
import '../../../domain/entities/user.dart';
import '../users/users_management_page.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/orders_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              'app.title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              // User Management Button (only for admins/managers)
              if (currentUser?.hasPermission(Permission.userView) ?? false)
                IconButton(
                  icon: const Icon(Icons.people),
                  tooltip: 'users.title'.tr(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  UsersManagementPage(),
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
                tooltip: 'dashboard.account'.tr(),
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
                          currentUser?.name ?? 'dashboard.user'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            currentUser?.role.displayName ?? 'dashboard.user'.tr(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getRoleColor(currentUser?.role),
                          labelStyle: const TextStyle(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),

                  // Profile
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 12),
                        Text('dashboard.my_profile'.tr()),
                      ],
                    ),
                  ),

                  // ✅ Language Switcher
                  PopupMenuItem(
                    value: 'language',
                    child: Row(
                      children: [
                        const Icon(Icons.language, size: 20),
                        const SizedBox(width: 12),
                        Text('dashboard.language'.tr()),
                        const Spacer(),
                        Text(
                          context.locale == const Locale('en') ? '🇬🇧 EN' : '🇸🇦 AR',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Theme Toggle
                  PopupMenuItem(
                    value: 'theme',
                    child: BlocBuilder<ThemeBloc, ThemeState>(
                      builder: (context, themeState) {
                        return Row(
                          children: [
                            Icon(
                              themeState.themeMode == ThemeMode.dark
                                  ? Icons.dark_mode
                                  : themeState.themeMode == ThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.brightness_auto,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text('dashboard.theme'.tr()),
                            const Spacer(),
                            Text(
                              themeState.themeMode == ThemeMode.dark
                                  ? 'dashboard.dark_mode'.tr()
                                  : themeState.themeMode == ThemeMode.light
                                  ? 'dashboard.light_mode'.tr()
                                  : 'dashboard.system_default'.tr(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const PopupMenuDivider(),

                  // Logout
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          'dashboard.logout_confirm'.tr(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  icon: const Icon(Icons.inventory_2),
                  text: 'navigation.inventory'.tr(),
                ),
                Tab(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  text: 'navigation.orders'.tr(),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children:  [
              InventoryTab(),
              OrdersTab(),
            ],
          ),
        );
      },
    );
  }

  // ✅ Language Switcher Dialog (FULLY LOCALIZED)
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.blue),
            const SizedBox(width: 8),
            Text('dashboard.choose_language'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: context.locale == const Locale('en')
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('en'));
                if (mounted) Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: const Text('العربية'),
              trailing: context.locale == const Locale('ar')
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('ar'));
                if (mounted) Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  // ✅ Theme Switcher Dialog (FULLY LOCALIZED & USING THEME BLOC!)
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.palette, color: Colors.purple),
                const SizedBox(width: 8),
                Text('dashboard.choose_theme'.tr()),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Light Mode (LOCALIZED)
                RadioListTile<ThemeMode>(
                  title: Text('dashboard.light_mode'.tr()),
                  subtitle: Text('dashboard.bright_and_clean'.tr()),
                  secondary: const Icon(Icons.light_mode, color: Colors.orange),
                  value: ThemeMode.light,
                  groupValue: themeState.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeBloc>().add(ChangeTheme(value));
                      Navigator.pop(dialogContext);
                    }
                  },
                ),

                // ✅ Dark Mode (LOCALIZED)
                RadioListTile<ThemeMode>(
                  title: Text('dashboard.dark_mode'.tr()),
                  subtitle: Text('dashboard.easy_on_eyes'.tr()),
                  secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
                  value: ThemeMode.dark,
                  groupValue: themeState.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeBloc>().add(ChangeTheme(value));
                      Navigator.pop(dialogContext);
                    }
                  },
                ),

                // ✅ System Default (LOCALIZED)
                RadioListTile<ThemeMode>(
                  title: Text('dashboard.system_default'.tr()),
                  subtitle: Text('dashboard.follow_system'.tr()),
                  secondary: const Icon(Icons.brightness_auto, color: Colors.grey),
                  value: ThemeMode.system,
                  groupValue: themeState.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeBloc>().add(const SetSystemTheme());
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('common.close'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ Logout Dialog (FULLY LOCALIZED)
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.orange),
            const SizedBox(width: 8),
            Text('dashboard.logout_confirm'.tr()),
          ],
        ),
        content: Text('dashboard.logout_message'.tr()),
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
            child: Text(
              'dashboard.logout_confirm'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Profile Dialog (FULLY LOCALIZED)
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('dashboard.user_profile'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('dashboard.name'.tr(), user.name),
            const SizedBox(height: 12),
            _buildProfileRow('dashboard.email'.tr(), user.email),
            const SizedBox(height: 12),
            _buildProfileRow('dashboard.role'.tr(), user.role.displayName),
            const SizedBox(height: 12),
            _buildProfileRow(
              'dashboard.account_created'.tr(),
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
            if (user.lastLogin != null) ...[
              const SizedBox(height: 12),
              _buildProfileRow(
                'dashboard.last_login'.tr(),
                '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year} ${user.lastLogin!.hour}:${user.lastLogin!.minute.toString().padLeft(2, '0')}',
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'dashboard.permissions'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.permissions.map((perm) {
                return Chip(
                  label: Text(perm.displayName, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
            style: const TextStyle(fontWeight: FontWeight.w500),
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
