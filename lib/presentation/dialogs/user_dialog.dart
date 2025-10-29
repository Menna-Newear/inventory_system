// ✅ presentation/dialogs/user_dialog.dart (WITH AUTO-REFRESH)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../../domain/entities/user.dart';

class UserDialog extends StatefulWidget {
  final User? user;

  const UserDialog({Key? key, this.user}) : super(key: key);

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late UserRole _selectedRole;
  late Set<Permission> _selectedPermissions;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role ?? UserRole.staff;
    _selectedPermissions = widget.user?.permissions.toSet() ?? {};
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.user != null;

    return BlocListener<AuthBloc, AuthState>(
      // ✅ Listen for state changes
      listener: (context, state) {
        if (state is UserCreated || state is UserUpdated) {
          // Close dialog on success
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is UserCreated ? 'User created successfully' : 'User updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Create New User'),
        content: Container(
          width: 500,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    enabled: !isEditing,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Password Field (only for new users)
                  if (!isEditing) ...[
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                  ],

                  // Role Dropdown
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(_getRoleIcon(role), size: 20),
                            SizedBox(width: 8),
                            Text(role.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          _selectedPermissions = value.defaultPermissions.toSet();
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),

                  // Active Status Switch
                  if (isEditing)
                    SwitchListTile(
                      title: Text('Active'),
                      subtitle: Text('User can log in and access the system'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  SizedBox(height: 16),

                  // Permissions Section
                  Text(
                    'Permissions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildPermissionsGrid(),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _handleSubmit,
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsGrid() {
    final groupedPermissions = <String, List<Permission>>{};
    for (var permission in Permission.values) {
      final category = permission.category;
      groupedPermissions.putIfAbsent(category, () => []).add(permission);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedPermissions.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((permission) {
                final isSelected = _selectedPermissions.contains(permission);
                return FilterChip(
                  label: Text(permission.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.user == null) {
      // ✅ Create new user
      context.read<AuthBloc>().add(
        CreateUserEvent(
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          permissions: _selectedPermissions.toList(),
        ),
      );
    } else {
      // ✅ Update existing user
      context.read<AuthBloc>().add(
        UpdateUserEvent(
          userId: widget.user!.id,
          name: _nameController.text.trim(),
          role: _selectedRole,
          permissions: _selectedPermissions.toList(),
          isActive: _isActive,
        ),
      );
    }
    // Don't close here - BlocListener will handle it
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
}
