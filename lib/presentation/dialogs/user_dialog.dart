// ✅ presentation/dialogs/user_dialog.dart (FULLY LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
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
  bool _isSubmitting = false;

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
      listener: (context, state) {
        if (_isSubmitting && state is Authenticated && state.allUsers != null) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? 'user_dialog.user_updated'.tr() : 'user_dialog.user_created'.tr(),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is AuthError) {
          _isSubmitting = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: AlertDialog(
        title: Text(isEditing ? 'user_dialog.edit_title'.tr() : 'user_dialog.create_title'.tr()),
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
                      labelText: 'user_dialog.full_name'.tr(),
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'user_dialog.validation.name_required'.tr();
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
                      labelText: 'user_dialog.email'.tr(),
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'user_dialog.validation.email_required'.tr();
                      }
                      if (!value.contains('@')) {
                        return 'user_dialog.validation.email_invalid'.tr();
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
                        labelText: 'user_dialog.password'.tr(),
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'user_dialog.validation.password_required'.tr();
                        }
                        if (value.length < 6) {
                          return 'user_dialog.validation.password_min_length'.tr();
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
                      labelText: 'user_dialog.role'.tr(),
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
                      title: Text('user_dialog.active'.tr()),
                      subtitle: Text('user_dialog.active_subtitle'.tr()),
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
                    'user_dialog.permissions'.tr(),
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
            child: Text('user_dialog.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: _handleSubmit,
            child: Text(isEditing ? 'user_dialog.update'.tr() : 'user_dialog.create'.tr()),
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

    setState(() {
      _isSubmitting = true;
    });

    if (widget.user == null) {
      // Create new user
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
      // Update existing user
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
