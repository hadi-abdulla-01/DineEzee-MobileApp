import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/user.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<KitchenUser> _users = [];
  List<Branch> _branches = [];
  List<String> _categories = [];
  bool _isLoading = true;
  
  // Filters
  String _nameFilter = '';
  String _roleFilter = 'All';
  String _branchFilter = 'All';
  
  final List<String> _roles = ['All', 'Admin', 'Manager', 'Server', 'Kitchen'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final branchId = authProvider.user?.branchId;
      
      // Load users, branches, and categories
      final users = await _firestoreService.getKitchenUsers();
      final branches = await _firestoreService.getBranches();
      
      // Get categories from settings
      List<String> categories = [];
      if (branchId != null) {
        final settings = await _firestoreService.getSettings(branchId);
        categories = settings?.menuCategories ?? [];
      }
      
      setState(() {
        _users = users;
        _branches = branches;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  List<KitchenUser> get _filteredUsers {
    return _users.where((user) {
      final nameMatch = _nameFilter.isEmpty || 
          user.username.toLowerCase().contains(_nameFilter.toLowerCase());
      final roleMatch = _roleFilter == 'All' || user.role == _roleFilter;
      final branchMatch = _branchFilter == 'All' || user.branchId == _branchFilter;
      
      return nameMatch && roleMatch && branchMatch;
    }).toList();
  }

  String _getBranchName(String? branchId) {
    if (branchId == null) return 'N/A';
    final branch = _branches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => Branch(
        id: '', 
        name: 'N/A', 
        isMain: false, 
        currencySymbol: '\$',
        currencyDecimalPlaces: 2,
        timezone: 'Asia/Kolkata',
      ),
    );
    return branch.name;
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        branches: _branches,
        categories: _categories,
        onSave: _handleAddUser,
      ),
    );
  }

  void _showEditUserDialog(KitchenUser user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        user: user,
        branches: _branches,
        categories: _categories,
        onSave: (updatedUser) => _handleEditUser(user.id, updatedUser),
      ),
    );
  }

  Future<void> _handleAddUser(KitchenUser user) async {
    try {
      await _firestoreService.addUser(user);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    }
  }

  Future<void> _handleEditUser(String userId, KitchenUser user) async {
    try {
      await _firestoreService.updateUser(userId, user);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(KitchenUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteUser(user.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Container(
                  padding: const EdgeInsets.all(16),
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  child: Column(
                    children: [
                      // Name filter
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search by username',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.white,
                        ),
                        onChanged: (value) => setState(() => _nameFilter = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Role filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _roleFilter,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.white,
                              ),
                              items: _roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _roleFilter = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Branch filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _branchFilter,
                              decoration: InputDecoration(
                                labelText: 'Branch',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.white,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'All',
                                  child: Text('All Branches'),
                                ),
                                ..._branches.map((branch) {
                                  return DropdownMenuItem(
                                    value: branch.id,
                                    child: Text(branch.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _branchFilter = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // User list
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryRed,
                                  child: Icon(
                                    user.isKitchen
                                        ? Icons.restaurant
                                        : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Role: ${user.role}'),
                                    Text('Branch: ${_getBranchName(user.branchId)}'),
                                    if (user.isKitchen && user.categories.isNotEmpty)
                                      Text(
                                        'Categories: ${user.categories.join(", ")}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: AppColors.primaryRed,
                                      onPressed: () => _showEditUserDialog(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: user.isAdmin
                                          ? null
                                          : () => _handleDeleteUser(user),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// User Form Dialog
class _UserFormDialog extends StatefulWidget {
  final KitchenUser? user;
  final List<Branch> branches;
  final List<String> categories;
  final Function(KitchenUser) onSave;

  const _UserFormDialog({
    this.user,
    required this.branches,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late String _selectedRole;
  late String? _selectedBranch;
  late List<String> _selectedCategories;
  late Map<String, Map<String, bool>> _permissions;

  final List<String> _roles = ['Admin', 'Manager', 'Server', 'Kitchen'];
  
  // Permission configuration matching web app
  final List<Map<String, dynamic>> _permissionConfig = [
    {'key': 'dashboard', 'label': 'Dashboard', 'rights': ['view']},
    {'key': 'tableOrder', 'label': 'Table Order', 'rights': ['view']},
    {'key': 'tables', 'label': 'Table Management', 'rights': ['view', 'create', 'edit', 'delete']},
    {'key': 'menu', 'label': 'Menu Management', 'rights': ['view', 'create', 'edit', 'delete']},
    {'key': 'kitchen', 'label': 'Kitchen View', 'rights': ['view']},
    {'key': 'sales', 'label': 'Sales Report', 'rights': ['view']},
    {'key': 'salesHistory', 'label': 'Sales History', 'rights': ['view', 'edit', 'delete']},
    {'key': 'onlineOrders', 'label': 'Online Orders', 'rights': ['view', 'create']},
    {'key': 'takeAway', 'label': 'Take Away', 'rights': ['view', 'create']},
    {'key': 'userManagement', 'label': 'User Management', 'rights': ['view', 'create', 'edit', 'delete']},
    {'key': 'settings', 'label': 'Settings', 'rights': ['view', 'edit']},
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController(text: widget.user?.password ?? '');
    _selectedRole = widget.user?.role ?? 'Kitchen';
    _selectedBranch = widget.user?.branchId ?? widget.branches.firstOrNull?.id;
    _selectedCategories = List.from(widget.user?.categories ?? []);
    _permissions = Map.from(widget.user?.permissions ?? {});
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final user = KitchenUser(
        id: widget.user?.id ?? '',
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        branchId: _selectedBranch,
        categories: _selectedRole == 'Kitchen' ? _selectedCategories : [],
        permissions: _permissions,
      );
      
      widget.onSave(user);
      Navigator.pop(context);
    }
  }

  void _togglePermission(String menu, String right, bool value) {
    setState(() {
      if (!_permissions.containsKey(menu)) {
        _permissions[menu] = {};
      }
      _permissions[menu]![right] = value;
      
      // If unchecking view, uncheck all other rights
      if (right == 'view' && !value) {
        _permissions[menu] = {'view': false, 'create': false, 'edit': false, 'delete': false};
      }
      // If checking any other right, automatically check view
      if (right != 'view' && value) {
        _permissions[menu]!['view'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.user == null ? 'Add User' : 'Edit User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Role
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(value: role, child: Text(role));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Branch
                      DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.branches.map((branch) {
                          return DropdownMenuItem(
                            value: branch.id,
                            child: Text(branch.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBranch = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Branch is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Categories (Kitchen only)
                      if (_selectedRole == 'Kitchen') ...[
                        const Text(
                          'Accessible Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['All', ...widget.categories].map((category) {
                            final isSelected = _selectedCategories.contains(category);
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (category == 'All') {
                                    _selectedCategories = selected ? ['All'] : [];
                                  } else {
                                    _selectedCategories.remove('All');
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Permissions
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._permissionConfig.map((config) {
                        final menuKey = config['key'] as String;
                        final label = config['label'] as String;
                        final rights = config['rights'] as List<String>;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  children: rights.map((right) {
                                    final isChecked = _permissions[menuKey]?[right] ?? false;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: isChecked,
                                          onChanged: (value) {
                                            _togglePermission(menuKey, right, value ?? false);
                                          },
                                        ),
                                        Text(
                                          right[0].toUpperCase() + right.substring(1),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.user == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
