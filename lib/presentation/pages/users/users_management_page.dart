// ✅ presentation/pages/users/users_management_page.dart (FULLY LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../domain/entities/user.dart';
import '../../dialogs/user_dialog.dart';

class UsersManagementPage extends StatefulWidget {
  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(LoadAllUsers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people),
            SizedBox(width: 12),
            Text('users_page.title'.tr()),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<AuthBloc>().add(LoadAllUsers()),
            tooltip: 'users_page.refresh'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, isDark),
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is UserManagementLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'users_page.loading_users'.tr(),
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  );
                }

                if (state is Authenticated && state.allUsers != null) {
                  final users = _filterUsers(state.allUsers!);

                  if (users.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildUsersTable(users, state.user, theme, isDark);
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'users_page.no_users_loaded'.tr(),
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.read<AuthBloc>().add(LoadAllUsers()),
                        icon: Icon(Icons.refresh),
                        label: Text('users_page.load_users'.tr()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, null),
        icon: Icon(Icons.person_add),
        label: Text('users_page.add_user'.tr()),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'users_page.search_hint'.tr(),
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildUsersTable(List<User> users, User currentUser, ThemeData theme, bool isDark) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 900,
      columns: [
        DataColumn2(label: Text('users_page.name'.tr()), size: ColumnSize.L),
        DataColumn2(label: Text('users_page.email'.tr()), size: ColumnSize.L),
        DataColumn2(label: Text('users_page.role'.tr()), size: ColumnSize.M),
        DataColumn2(label: Text('users_page.status'.tr()), size: ColumnSize.S),
        DataColumn2(label: Text('users_page.last_login'.tr()), size: ColumnSize.M),
        DataColumn2(label: Text('users_page.actions'.tr()), size: ColumnSize.M),
      ],
      rows: users.map((user) => _buildUserRow(user, currentUser, theme)).toList(),
    );
  }

  DataRow2 _buildUserRow(User user, User currentUser, ThemeData theme) {
    final isCurrentUser = user.id == currentUser.id;

    return DataRow2(
      color: MaterialStateProperty.resolveWith<Color?>(
            (states) => isCurrentUser ? theme.primaryColor.withOpacity(0.1) : null,
      ),
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user.role),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUser)
                      Text(
                        'users_page.you'.tr(),
                        style: TextStyle(fontSize: 12, color: theme.primaryColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(_buildRoleChip(user.role)),
        DataCell(_buildStatusChip(user.isActive)),
        DataCell(
          Text(
            user.lastLogin != null
                ? _formatDateTime(user.lastLogin!)
                : 'users_page.never'.tr(),
            style: TextStyle(fontSize: 13),
          ),
        ),
        DataCell(_buildActionButtons(user, currentUser)),
      ],
    );
  }

  Widget _buildRoleChip(UserRole role) {
    return Chip(
      label: Text(role.displayName),
      backgroundColor: _getRoleColor(role).withOpacity(0.2),
      labelStyle: TextStyle(
        color: _getRoleColor(role),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      avatar: Icon(
        _getRoleIcon(role),
        size: 16,
        color: _getRoleColor(role),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Chip(
      label: Text(isActive ? 'users_page.active'.tr() : 'users_page.inactive'.tr()),
      backgroundColor: isActive ? Colors.green[100] : Colors.red[100],
      labelStyle: TextStyle(
        color: isActive ? Colors.green[800] : Colors.red[800],
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      avatar: Icon(
        isActive ? Icons.check_circle : Icons.cancel,
        size: 16,
        color: isActive ? Colors.green[800] : Colors.red[800],
      ),
    );
  }

  Widget _buildActionButtons(User user, User currentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, size: 18),
          onPressed: () => _showUserDialog(context, user),
          tooltip: 'users_page.edit_user'.tr(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.1),
            foregroundColor: Colors.blue,
          ),
        ),
        if (user.id != currentUser.id) ...[
          SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete, size: 18),
            onPressed: () => _confirmDeleteUser(context, user),
            tooltip: 'users_page.delete_user'.tr(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'users_page.no_users_found'.tr(),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'users_page.adjust_search'.tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return users;
    }
    return users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery!) ||
          user.email.toLowerCase().contains(_searchQuery!);
    }).toList();
  }

  void _showUserDialog(BuildContext context, User? user) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: UserDialog(user: user),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('users_page.delete_title'.tr()),
          ],
        ),
        content: Text(
          'users_page.delete_confirm'.tr(namedArgs: {'name': user.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('users_page.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(DeleteUserEvent(user.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('users_page.user_deleted'.tr()),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('users_page.delete'.tr(), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.staff:
        return Colors.green;
      case UserRole.viewer:
        return Colors.orange;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.staff:
        return Icons.person;
      case UserRole.viewer:
        return Icons.visibility;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'users_page.time.minutes_ago'.tr(namedArgs: {'count': '${difference.inMinutes}'});
      }
      return 'users_page.time.hours_ago'.tr(namedArgs: {'count': '${difference.inHours}'});
    } else if (difference.inDays < 7) {
      return 'users_page.time.days_ago'.tr(namedArgs: {'count': '${difference.inDays}'});
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
