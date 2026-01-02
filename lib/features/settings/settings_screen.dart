import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/category.dart';
import '../../models/settings.dart';
import '../../models/branch.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Category> _categories = [];
  List<MealSession> _mealSessions = [];
  RestaurantSettings? _settings;
  List<Branch> _branches = [];
  Branch? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      debugPrint('🔄 Loading settings data...');
      
      // Fetch branches
      final branches = await _firestoreService.getBranches();
      debugPrint('✅ Loaded ${branches.length} branches');
      Branch? selectedBranch;
      
      if (branches.isNotEmpty) {
        // Keep currently selected branch if valid, otherwise select main
        if (_selectedBranch != null && branches.any((b) => b.id == _selectedBranch!.id)) {
          selectedBranch = branches.firstWhere((b) => b.id == _selectedBranch!.id);
        } else {
          selectedBranch = branches.firstWhere(
            (b) => b.isMain,
            orElse: () => branches.first,
          );
        }
        debugPrint('✅ Selected branch: ${selectedBranch.name} (${selectedBranch.id})');
      }
      
      // Fetch settings for selected branch
      RestaurantSettings? settings;
      List<Category> categories = [];
      
      if (selectedBranch != null) {
        settings = await _firestoreService.getSettings(selectedBranch.id);
        
        // Get categories from settings.menuCategories (web app format)
        if (settings != null && settings.menuCategories != null) {
          categories = settings.menuCategories!
              .asMap()
              .entries
              .map((entry) => Category(
                    id: 'cat-${entry.key}',
                    name: entry.value,
                    order: entry.key,
                  ))
              .toList();
          debugPrint('✅ Loaded ${categories.length} categories from settings');
        } else {
          debugPrint('⚠️ No categories found in settings');
        }
        
        if (settings != null) {
          debugPrint('✅ Loaded settings: currency=${settings.currencySymbol}, sessions=${settings.mealSessions.length}');
          for (var session in settings.mealSessions) {
            debugPrint('   - ${session.name}: ${session.startTime}-${session.endTime}');
          }
        } else {
          debugPrint('⚠️ No settings found for branch');
        }
      }

      setState(() {
        _branches = branches;
        _selectedBranch = selectedBranch;
        _categories = categories;
        _mealSessions = settings?.mealSessions ?? [];
        _settings = settings;
        _isLoading = false;
      });
      
      debugPrint('✅ Settings data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading settings: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        title: const Text('Settings'),
        actions: [
          const ThemeToggleButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryYellow,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Global Settings', icon: Icon(Icons.public, size: 20)),
            Tab(text: 'Branch Settings', icon: Icon(Icons.store, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalSettingsTab(),
                _buildBranchSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildGlobalSettingsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              'These settings apply across all branches unless overridden.',
              Icons.info_outline,
            ),
            const SizedBox(height: 16),
            
            _buildSettingCard(
              icon: Icons.business,
              iconColor: Colors.blue,
              title: 'Restaurant Details',
              subtitle: 'Manage your restaurant\'s global name and address',
              onTap: () => _showRestaurantDetailsDialog(),
            ),
            
            _buildSettingCard(
              icon: Icons.store,
              iconColor: Colors.purple,
              title: 'Branch Management',
              subtitle: 'Add, remove, or set the main branch',
              badge: '${_branches.length}',
              onTap: () => _showBranchManagementDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSettingsTab() {
    return Column(
      children: [
        // Branch Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryRed),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<Branch>(
                  value: _selectedBranch,
                  decoration: const InputDecoration(
                    labelText: 'Select Branch',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch,
                      child: Row(
                        children: [
                          Text(branch.name),
                          if (branch.isMain) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MAIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (branch) async {
                    if (branch != null) {
                      setState(() {
                        _selectedBranch = branch;
                        _isLoading = true;
                      });
                      
                      try {
                        final settings = await _firestoreService.getSettings(branch.id);
                        
                        // Parse categories for the selected branch
                        List<Category> categories = [];
                        if (settings != null && settings.menuCategories != null) {
                          categories = settings.menuCategories!
                              .asMap()
                              .entries
                              .map((entry) => Category(
                                    id: 'cat-${entry.key}',
                                    name: entry.value,
                                    order: entry.key,
                                  ))
                              .toList();
                        }

                        setState(() {
                          _settings = settings;
                          _mealSessions = settings?.mealSessions ?? [];
                          _categories = categories;
                          _isLoading = false;
                        });
                      } catch (e) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Settings List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(
                    'Configure settings for ${_selectedBranch?.name ?? "this branch"}',
                    Icons.settings,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSettingCard(
                    icon: Icons.settings,
                    iconColor: Colors.orange,
                    title: 'General Settings',
                    subtitle: 'Branch name, address, currency, and tax',
                    onTap: () => _showGeneralSettingsDialog(),
                  ),
                  
                  _buildSettingCard(
                    icon: Icons.category,
                    iconColor: Colors.green,
                    title: 'Menu Categories',
                    subtitle: 'Meals, Snacks, Beverages, and more',
                    badge: '${_categories.length}',
                    onTap: () => _navigateToCategoriesPage(),
                  ),
                  
                  _buildSettingCard(
                    icon: Icons.schedule,
                    iconColor: Colors.indigo,
                    title: 'Meal Sessions',
                    subtitle: 'Breakfast, lunch, dinner times',
                    badge: '${_mealSessions.length}',
                    onTap: () => _navigateToMealSessionsPage(),
                  ),
                  
                  _buildSettingCard(
                    icon: Icons.shopping_cart,
                    iconColor: AppColors.primaryRed,
                    title: 'Online Order Settings',
                    subtitle: 'Delivery fees, minimum order values',
                    highlighted: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  
                  _buildSettingCard(
                    icon: Icons.receipt,
                    iconColor: Colors.teal,
                    title: 'Invoice & Numbering',
                    subtitle: 'Custom prefixes and numbering',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  
                  _buildSettingCard(
                    icon: Icons.print,
                    iconColor: Colors.brown,
                    title: 'Printing',
                    subtitle: 'Printer settings and receipt templates',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlighted = false,
    String? badge,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: highlighted ? 4 : 2,
      color: highlighted 
          ? AppColors.primaryRed.withOpacity(0.05)
          : Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlighted 
                      ? AppColors.primaryRed 
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlighted ? Colors.white : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              color: highlighted ? AppColors.primaryRed : null,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: highlighted 
                    ? AppColors.primaryRed 
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestaurantDetailsDialog() {
    final nameController = TextEditingController(text: _settings?.restaurantName ?? '');
    final addressController = TextEditingController(text: _settings?.restaurantAddress ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurant Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restaurant details saved!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBranchManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Branch Management'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _branches.length,
            itemBuilder: (context, index) {
              final branch = _branches[index];
              return ListTile(
                leading: Icon(Icons.store, color: AppColors.primaryRed),
                title: Text(branch.name),
                subtitle: Text(branch.restaurantAddress ?? 'No address'),
                trailing: branch.isMain
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MAIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGeneralSettingsDialog() {
    final currencyController = TextEditingController(text: _settings?.currencySymbol ?? '\$');
    int decimalPlaces = _settings?.currencyDecimalPlaces ?? 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('General Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: 'Currency Symbol',
                  border: OutlineInputBorder(),
                  hintText: '\$, €, ₹, etc.',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: decimalPlaces,
                decoration: const InputDecoration(
                  labelText: 'Decimal Places',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                items: [0, 1, 2, 3].map((places) {
                  return DropdownMenuItem(
                    value: places,
                    child: Text('$places decimal places'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => decimalPlaces = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedBranch == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No branch selected')),
                  );
                  return;
                }

                try {
                  print('💾 Saving settings: currency=${currencyController.text}, decimal=$decimalPlaces');
                  
                  await _firestoreService.updateSettings(
                    _selectedBranch!.id,
                    {
                      'currencySymbol': currencyController.text.trim(),
                      'currencyDecimalPlaces': decimalPlaces,
                    },
                  );
                  
                  print('✅ Settings saved successfully');
                  
                  // Reload data to reflect changes
                  await _loadData();
                  
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error saving settings: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving settings: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategoriesPage() {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No branch selected')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesManagementPage(
          categories: _categories,
          branchId: _selectedBranch!.id,
          onRefresh: _loadData,
        ),
      ),
    );
  }

  void _navigateToMealSessionsPage() {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No branch selected')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealSessionsManagementPage(
          sessions: _mealSessions,
          branchId: _selectedBranch!.id,
          onRefresh: _loadData,
        ),
      ),
    );
  }
}

// ========== CATEGORIES MANAGEMENT PAGE ==========
class CategoriesManagementPage extends StatefulWidget {
  final List<Category> categories;
  final String branchId;
  final VoidCallback onRefresh;

  const CategoriesManagementPage({
    super.key,
    required this.categories,
    required this.branchId,
    required this.onRefresh,
  });

  @override
  State<CategoriesManagementPage> createState() => _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<Category> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Menu Categories'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No categories yet', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  key: ValueKey(category.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryYellow,
                      child: Icon(Icons.category, color: AppColors.primaryRed),
                    ),
                    title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddCategoryDialog(category: category, index: index);
                        } else if (value == 'delete') {
                          _deleteCategory(category, index);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddCategoryDialog(),
              backgroundColor: AppColors.primaryRed,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }




  void _showAddCategoryDialog({Category? category, int? index}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Add Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Appetizers, Main Course',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter category name')),
                );
                return;
              }

              try {
                final newName = nameController.text.trim();
                
                if (isEdit) {
                  await _firestoreService.updateCategory(
                    widget.branchId,
                    category!.name,
                    newName,
                  );
                  setState(() {
                    _categories[index!] = Category(
                      id: category.id,
                      name: newName,
                      order: category.order,
                    );
                  });
                } else {
                  await _firestoreService.addCategory(
                    widget.branchId,
                    newName,
                  );
                  setState(() {
                    _categories.add(Category(
                      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
                      name: newName,
                      order: _categories.length,
                    ));
                  });
                }

                widget.onRefresh(); // Reload to get updated categories
                Navigator.pop(context);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Category updated!' : 'Category added!')),
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
    );
  }

  Future<void> _deleteCategory(Category category, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
        await _firestoreService.deleteCategory(widget.branchId, category.name);
        
        if (mounted) {
          setState(() {
            _categories.removeAt(index);
          });
        }
        
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// ========== MEAL SESSIONS MANAGEMENT PAGE ==========
class MealSessionsManagementPage extends StatefulWidget {
  final List<MealSession> sessions;
  final String branchId;
  final VoidCallback onRefresh;

  const MealSessionsManagementPage({
    super.key,
    required this.sessions,
    required this.branchId,
    required this.onRefresh,
  });

  @override
  State<MealSessionsManagementPage> createState() => _MealSessionsManagementPageState();
}

class _MealSessionsManagementPageState extends State<MealSessionsManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<MealSession> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.sessions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Meal Sessions'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No meal sessions configured', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Meal Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: session.isActive ? AppColors.primaryYellow : Colors.grey[300],
                      child: Icon(
                        Icons.restaurant,
                        color: session.isActive ? AppColors.primaryRed : Colors.grey[600],
                      ),
                    ),
                    title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${session.startTime} - ${session.endTime}'),
                          ],
                        ),
                        if (session.greeting.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.greeting,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: session.isActive ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            session.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(session: session, index: index);
                            } else if (value == 'delete') {
                              _deleteSession(session, index);
                            }
                          },
                        ),
                      ],
                    ),
                    isThreeLine: session.greeting.isNotEmpty,
                  ),
                );
              },
            ),
      floatingActionButton: _sessions.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddEditDialog(),
              backgroundColor: AppColors.primaryRed,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddEditDialog({MealSession? session, int? index}) {
    final isEdit = session != null;
    final nameController = TextEditingController(text: session?.name ?? '');
    final greetingController = TextEditingController(text: session?.greeting ?? '');
    final messageController = TextEditingController(text: session?.displayMessage ?? '');
    
    TimeOfDay startTime = session != null
        ? TimeOfDay(
            hour: int.parse(session.startTime.split(':')[0]),
            minute: int.parse(session.startTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);
    
    TimeOfDay endTime = session != null
        ? TimeOfDay(
            hour: int.parse(session.endTime.split(':')[0]),
            minute: int.parse(session.endTime.split(':')[1]),
          )
        : const TimeOfDay(hour: 17, minute: 0);
    
    bool isActive = session?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Meal Session' : 'Add Meal Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Session Name *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Breakfast, Lunch',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: greetingController,
                  decoration: const InputDecoration(
                    labelText: 'Greeting',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Good Morning',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Display Message',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Enjoy your breakfast',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text('Start: ${startTime.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text('End: ${endTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter session name')),
                  );
                  return;
                }

                try {
                  debugPrint('📝 Editing session: ${session?.name}, ID: "${session?.id}"');
                  
                  // Generate new ID if session ID is empty/null
                  final sessionId = (session?.id == null || session!.id.isEmpty)
                      ? 'session-${DateTime.now().millisecondsSinceEpoch}'
                      : session.id;
                  
                  final newSession = MealSession(
                    id: sessionId,
                    name: nameController.text.trim(),
                    greeting: greetingController.text.trim(),
                    displayMessage: messageController.text.trim(),
                    startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                    isActive: isActive,
                  );
                  
                  debugPrint('📝 New session ID: "${newSession.id}"');

                  if (isEdit) {
                    // If original session had no ID, use index-based update
                    if (session.id.isEmpty) {
                      debugPrint('⚠️ Session had no ID, updating by index: $index');
                      await _firestoreService.updateMealSessionByIndex(widget.branchId, index!, newSession);
                    } else {
                      await _firestoreService.updateMealSession(widget.branchId, session.id, newSession);
                    }
                    setState(() {
                      _sessions[index!] = newSession;
                    });
                  } else {
                    await _firestoreService.addMealSession(widget.branchId, newSession);
                  }

                  widget.onRefresh();
                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Session updated!' : 'Session added!')),
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

  Future<void> _deleteSession(MealSession session, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal Session'),
        content: Text('Are you sure you want to delete "${session.name}"?'),
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
        await _firestoreService.deleteMealSession(widget.branchId, session.id);
        setState(() {
          _sessions.removeAt(index);
        });
        widget.onRefresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
