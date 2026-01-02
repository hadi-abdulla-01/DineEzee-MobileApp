import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/menu_item.dart';
import '../../models/category.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  List<Category> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final branchId = user?.branchId;

      final menuItems = await _firestoreService.getMenuItems(branchId);
      final categories = await _firestoreService.getCategories();

      setState(() {
        _menuItems = menuItems;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == null) return _menuItems;
    return _menuItems.where((item) => item.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: const Text('Menu Management'),
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', null),
                        const SizedBox(width: 8),
                        ..._categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(cat.name, cat.name),
                        )),
                      ],
                    ),
                  ),
                ),

                // Menu Items List
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No menu items found',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildMenuItemCard(item);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = value);
      },
      selectedColor: AppColors.primaryYellow,
      checkmarkColor: AppColors.primaryRed,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryRed : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant),
              ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.category} • \$${item.price.toStringAsFixed(2)}',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isAvailable ? Icons.check_circle : Icons.cancel,
              color: item.isAvailable ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditDialog(item: item);
                } else if (value == 'delete') {
                  _deleteItem(item);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog({MenuItem? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    String? selectedCategory = item?.category ?? (_categories.isNotEmpty ? _categories.first.name : null);
    bool isAvailable = item?.isAvailable ?? true;
    String? imageUrl = item?.imageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Preview
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Price
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 12),

                // Availability Switch
                SwitchListTile(
                  title: const Text('Available'),
                  value: isAvailable,
                  onChanged: (value) {
                    setDialogState(() => isAvailable = value);
                  },
                  activeColor: AppColors.primaryRed,
                ),

                // Image URL (simplified - in production, use image picker)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                  onChanged: (value) {
                    setDialogState(() => imageUrl = value.isEmpty ? null : value);
                  },
                  controller: TextEditingController(text: imageUrl),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || 
                    priceController.text.isEmpty || 
                    selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                try {
                  final price = double.parse(priceController.text);
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  
                  final menuItem = MenuItem(
                    id: item?.id ?? '',
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    price: price,
                    category: selectedCategory!,
                    imageUrl: imageUrl,
                    isAvailable: isAvailable,
                    branchId: user?.branchId,
                    sessionIds: item?.sessionIds ?? [], // Keep existing or empty
                  );

                  if (isEdit) {
                    await _firestoreService.updateMenuItem(item!.id, menuItem);
                  } else {
                    await _firestoreService.addMenuItem(menuItem);
                  }

                  Navigator.pop(context);
                  _loadData();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Item updated!' : 'Item added!')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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

    if (confirm == true) {
      try {
        await _firestoreService.deleteMenuItem(item.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
