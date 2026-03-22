import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../services/user_service.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _deletingUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await UserService.fetchAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.email.toLowerCase().contains(query) ||
          (user.fullName?.toLowerCase().contains(query) ?? false) ||
          user.role.name.toLowerCase().contains(query) ||
          user.assignedWorkSummary.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (currentUser) {
        if (currentUser == null || !currentUser.canManageUsers) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 64,
                  color: AppTheme.textLight.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text('Access Denied', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(
                  'You do not have permission to access this page.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Management', style: AppTextStyles.heading2),
                        const SizedBox(height: 4),
                        Text(
                          'Assign module access, change roles, and control account status',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New users register at login screen',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search users by name, email, role, or assigned work...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 24),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildUsersTable(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final adminCount = _users.where((u) => u.role == UserRole.admin).length;
    final staffCount = _users.where((u) => u.role == UserRole.staff).length;
    final factoryCount = _users.where((u) => u.role == UserRole.factory).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'Total Users',
            _users.length.toString(),
            Icons.people_rounded,
            AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Admins',
            adminCount.toString(),
            Icons.admin_panel_settings_rounded,
            AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Staff',
            staffCount.toString(),
            Icons.people_outline_rounded,
            AppTheme.successColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Factory',
            factoryCount.toString(),
            Icons.inventory_2_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.heading3),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppTheme.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: AppTextStyles.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 60,
                  child: Text(
                    'S.No',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Role',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Assigned Work',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(
                  width: 168,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserRow(index + 1, user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(int index, UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text('$index')),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                  child: Text(
                    user.displayName[0].toUpperCase(),
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(user.displayName, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user.email, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.roleDisplayName,
                style: AppTextStyles.caption.copyWith(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  user.assignedWorkLabels.isEmpty
                      ? [
                        Text(
                          'No modules assigned',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ]
                      : user.assignedWorkLabels
                          .map(
                            (label) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    user.isActive
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: AppTextStyles.caption.copyWith(
                  color:
                      user.isActive
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 168,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: AppTheme.primaryColor,
                  onPressed: () => _showEditUserDialog(context, user),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: Icon(
                    user.isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 20,
                  ),
                  color:
                      user.isActive
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                  onPressed: () => _toggleUserStatus(user),
                  tooltip: user.isActive ? 'Deactivate' : 'Activate',
                ),
                IconButton(
                  icon:
                      _deletingUserId == user.id
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.delete_outline_rounded, size: 20),
                  color:
                      user.id == ref.read(currentUserProvider).value?.id
                          ? AppTheme.textLight
                          : AppTheme.errorColor,
                  onPressed:
                      _deletingUserId == user.id ||
                              user.id == ref.read(currentUserProvider).value?.id
                          ? null
                          : () => _deleteUser(user),
                  tooltip:
                      user.id == ref.read(currentUserProvider).value?.id
                          ? 'You cannot delete your own account'
                          : 'Delete User',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppTheme.errorColor;
      case UserRole.staff:
        return AppTheme.successColor;
      case UserRole.factory:
        return Colors.orange;
    }
  }

  Future<void> _showEditUserDialog(BuildContext context, UserModel user) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    UserRole selectedRole = user.role;
    bool applicationsAccess = user.applicationsAccess ?? user.canAccessApplications;
    bool paymentsAccess = user.paymentsAccess ?? user.canAccessPayments;
    bool inventoryAccess = user.inventoryAccess ?? user.canAccessInventory;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Text('Edit User'),
                    ],
                  ),
                  content: SizedBox(
                    width: 450,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.email,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (optional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<UserRole>(
                            value: selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              prefixIcon: Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                            ),
                            items:
                                UserRole.values.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getRoleIcon(role),
                                          size: 18,
                                          color: _getRoleColor(role),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_getRoleDisplayName(role)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedRole = value;
                                  if (selectedRole == UserRole.admin) {
                                    applicationsAccess = true;
                                    paymentsAccess = true;
                                    inventoryAccess = true;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assign Work Modules',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: selectedRole == UserRole.admin || applicationsAccess,
                                  onChanged:
                                      selectedRole == UserRole.admin
                                          ? null
                                          : (value) => setState(
                                            () => applicationsAccess = value ?? false,
                                          ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Applications'),
                                ),
                                CheckboxListTile(
                                  value: selectedRole == UserRole.admin || paymentsAccess,
                                  onChanged:
                                      selectedRole == UserRole.admin
                                          ? null
                                          : (value) => setState(
                                            () => paymentsAccess = value ?? false,
                                          ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Payments'),
                                ),
                                CheckboxListTile(
                                  value: selectedRole == UserRole.admin || inventoryAccess,
                                  onChanged:
                                      selectedRole == UserRole.admin
                                          ? null
                                          : (value) => setState(
                                            () => inventoryAccess = value ?? false,
                                          ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Inventory'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getRoleDescription(selectedRole),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
          ),
    );

    if (result == true) {
      try {
        await UserService.updateUser(
          user.copyWith(
            fullName: nameController.text.trim(),
            phone:
                phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
            role: selectedRole,
            applicationsAccess:
                selectedRole == UserRole.admin ? true : applicationsAccess,
            paymentsAccess:
                selectedRole == UserRole.admin ? true : paymentsAccess,
            inventoryAccess:
                selectedRole == UserRole.admin ? true : inventoryAccess,
          ),
        );
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(user.isActive ? 'Deactivate User?' : 'Activate User?'),
            content: Text(
              user.isActive
                  ? 'This user will no longer be able to log in.'
                  : 'This user will be able to log in again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      user.isActive
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(user.isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await UserService.updateUser(user.copyWith(isActive: !user.isActive));
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'User ${user.isActive ? 'deactivated' : 'activated'} successfully',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User?'),
            content: Text(
              'This will remove ${user.displayName} from the app, revoke all access, and delete the user from Supabase. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete User'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _deletingUserId = user.id);
    try {
      await UserService.deleteUser(user);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingUserId = null);
      }
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.staff:
        return Icons.people_outline_rounded;
      case UserRole.factory:
        return Icons.inventory_2_rounded;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.factory:
        return 'Factory Employee';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full access: Can manage users, settings, and all applications.';
      case UserRole.staff:
        return 'Employee profile: Assign specific modules like applications, payments, or inventory.';
      case UserRole.factory:
        return 'Factory profile: Usually used for inventory-focused work, but modules can be assigned separately.';
    }
  }
}
