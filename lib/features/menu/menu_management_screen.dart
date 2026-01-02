import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/menu_item.dart';
import '../../models/settings.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  List<MealSession> _mealSessions = [];
  String? _selectedCategory;
  String _currencySymbol = '₹'; // Default to rupees

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
      
      debugPrint('🔍 Menu Management - Loading data for branchId: $branchId');
      debugPrint('🔍 User: ${user?.username}, Role: ${user?.role}');

      final menuItems = await _firestoreService.getMenuItems(branchId);
      debugPrint('✅ Loaded ${menuItems.length} menu items');
      
      // Get settings for categories and meal sessions
      RestaurantSettings? settings;
      if (branchId != null) {
        settings = await _firestoreService.getSettings(branchId);
        debugPrint('✅ Settings loaded: currency=${settings?.currencySymbol}, sessions=${settings?.mealSessions.length}');
        debugPrint('📋 Categories: ${settings?.menuCategories}');
        debugPrint('🍽️ Meal Sessions: ${settings?.mealSessions.map((s) => s.name).toList()}');
      } else {
        debugPrint('⚠️ No branchId found, using defaults');
      }

      setState(() {
        _menuItems = menuItems;
        _categories = settings?.menuCategories ?? ['Meals', 'Snacks', 'Beverages', 'Desserts'];
        _mealSessions = settings?.mealSessions ?? [];
        _currencySymbol = settings?.currencySymbol ?? '₹';
        _isLoading = false;
      });
      
      debugPrint('💰 Currency symbol set to: $_currencySymbol');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading menu data: $e');
      debugPrint('Stack: $stackTrace');
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
                          child: _buildCategoryChip(cat, cat),
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

  Widget _buildImage(String imageSource, String itemName) {
    if (imageSource.startsWith('data:image')) {
      try {
        final base64Data = imageSource.split(',')[1];
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, width: 60, height: 60, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder());
      } catch (e) {
        debugPrint('❌ Base64 error for $itemName: $e');
        return _buildPlaceholder();
      }
    } else {
      return CachedNetworkImage(imageUrl: imageSource, width: 60, height: 60, fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 60, height: 60, color: Colors.grey[300],
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        errorWidget: (_, __, ___) => _buildPlaceholder());
    }
  }

  Widget _buildPlaceholder() => Container(width: 60, height: 60, color: Colors.grey[300],
    child: const Icon(Icons.restaurant, color: Colors.grey));

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(item.imageUrl!, item.name),
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
          '${item.category} • $_currencySymbol${item.price.toStringAsFixed(2)}',
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

  void _showAddEditDialog({MenuItem? item}) async {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    String? selectedCategory = item?.category ?? (_categories.isNotEmpty ? _categories.first : null);
    bool isAvailable = item?.isAvailable ?? true;
    File? selectedImage;
    String? existingImageUrl = item?.imageUrl;
    List<String> selectedSessionIds = List.from(item?.sessionIds ?? []);
    bool isSaving = false; // Track saving state
    
    // Debug logging
    debugPrint('🔧 Opening dialog for ${isEdit ? "EDIT" : "ADD"}');
    if (isEdit) {
      debugPrint('📝 Item: ${item!.name}');
      debugPrint('🖼️ Existing image URL: $existingImageUrl');
      debugPrint('🍽️ Item sessionIds: ${item.sessionIds}');
      debugPrint('🍽️ Selected sessionIds: $selectedSessionIds');
      debugPrint('🍽️ Available sessions: ${_mealSessions.map((s) => '${s.name}(${s.id})').toList()}');
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while saving
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => WillPopScope(
          onWillPop: () async => !isSaving, // Prevent back button while saving
          child: AlertDialog(
          title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Section - Show if there's a selected image OR existing URL
                if (selectedImage != null || (existingImageUrl != null && existingImageUrl!.isNotEmpty))
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: selectedImage != null
                          ? DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : (existingImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(existingImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                  ),

                // Image Picker Buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_photo_alternate, color: AppColors.primaryRed, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Image',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final image = await _imagePicker.pickImage(
                                  source: ImageSource.camera,
                                  maxWidth: 1024,
                                  maxHeight: 1024,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    selectedImage = File(image.path);
                                    existingImageUrl = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.camera_alt, size: 20),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryRed,
                                elevation: 0,
                                side: BorderSide(color: AppColors.primaryRed),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final image = await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1024,
                                  maxHeight: 1024,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    selectedImage = File(image.path);
                                    existingImageUrl = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo_library, size: 20),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                  decoration: InputDecoration(
                    labelText: 'Price *',
                    border: const OutlineInputBorder(),
                    prefixText: '$_currencySymbol ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 12),

                // Meal Sessions Multi-Select
                if (_mealSessions.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Meal Sessions',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealSessions.map((session) {
                      final isSelected = selectedSessionIds.contains(session.id);
                      debugPrint('🔍 Session ${session.name} (${session.id}): selected=$isSelected');
                      return FilterChip(
                        label: Text(session.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedSessionIds.add(session.id);
                              debugPrint('➕ Added ${session.name} to selection');
                            } else {
                              selectedSessionIds.remove(session.id);
                              debugPrint('➖ Removed ${session.name} from selection');
                            }
                            debugPrint('📝 Current selection: $selectedSessionIds');
                          });
                        },
                        selectedColor: AppColors.primaryYellow,
                        checkmarkColor: AppColors.primaryRed,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Availability Switch
                SwitchListTile(
                  title: const Text('Available'),
                  value: isAvailable,
                  onChanged: (value) {
                    setDialogState(() => isAvailable = value);
                  },
                  activeColor: AppColors.primaryRed,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                
                debugPrint('💾 Save button pressed');
                debugPrint('📝 Name: ${nameController.text}');
                debugPrint('💰 Price: ${priceController.text}');
                debugPrint('📂 Category: $selectedCategory');
                
                if (nameController.text.isEmpty || 
                    priceController.text.isEmpty || 
                    selectedCategory == null) {
                  debugPrint('⚠️ Validation failed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                try {
                  debugPrint('🔄 Starting save process...');
                  final price = double.parse(priceController.text);
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  
                  // Convert image to base64 if selected (like web app)
                  String? imageUrl = existingImageUrl;
                  if (selectedImage != null) {
                    try {
                      debugPrint('🖼️ Converting image to base64...');
                      final bytes = await selectedImage!.readAsBytes();
                      final base64Image = base64Encode(bytes);
                      // Create data URI (same format as web app)
                      imageUrl = 'data:image/jpeg;base64,$base64Image';
                      debugPrint('✅ Image converted to base64 (${base64Image.length} chars)');
                    } catch (e) {
                      debugPrint('❌ Image conversion failed: $e');
                      imageUrl = null;
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Image processing failed: $e'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                  
                  final menuItem = MenuItem(
                    id: item?.id ?? '',
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    price: price,
                    category: selectedCategory!,
                    imageUrl: imageUrl,
                    isAvailable: isAvailable,
                    branchId: user?.branchId,
                    sessionIds: selectedSessionIds,
                  );

                  debugPrint('💾 Saving to database...');
                  if (isEdit) {
                    await _firestoreService.updateMenuItem(item!.id, menuItem);
                    debugPrint('✅ Item updated');
                  } else {
                    await _firestoreService.addMenuItem(menuItem);
                    debugPrint('✅ Item added');
                  }

                  Navigator.pop(context);
                  _loadData();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Item updated!' : 'Item added!')),
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint('❌ Error saving: $e');
                  debugPrint('Stack: $stackTrace');
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
          ),
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
