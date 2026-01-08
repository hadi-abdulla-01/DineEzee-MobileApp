import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/order.dart' as models;
import '../../models/menu_item.dart';
import '../../models/settings.dart';
import '../../models/branch.dart';
import '../kitchen/kitchen_dashboard_screen.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/app_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  List<models.Order> _completedOrders = [];
  List<MenuItem> _menuItems = [];
  RestaurantSettings? _settings;
  
  // Branch selection for global admins
  List<Branch> _branches = [];
  String? _selectedBranchId; // null = "All Branches"
  bool _isGlobalAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _isGlobalAdmin = user?.isGlobalAdmin ?? false;
    
    if (_isGlobalAdmin) {
      await _loadBranches();
    }
    
    await _loadData();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _firestoreService.getBranches();
      setState(() {
        _branches = branches;
      });
      print('🏢 Loaded ${branches.length} branches');
    } catch (e) {
      print('❌ Error loading branches: $e');
    }
  }

  Future<void> _loadData() async {
    print('🔄 AdminDashboard: Starting data load...');
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      print('👤 User: ${user?.username}, Role: ${user?.role}, BranchId: ${user?.branchId}');
      
      // Determine which branch to load data for
      String? branchId;
      if (_isGlobalAdmin) {
        // Global admin: use selected branch (null = all branches)
        branchId = _selectedBranchId;
        print('🏢 Global Admin - Loading data for: ${branchId ?? "All Branches"}');
      } else {
        // Branch user: use their assigned branch
        branchId = user?.branchId;
        print('🏢 Branch User - Loading data for branch: $branchId');
      }

      // Fetch data with error handling for each
      List<models.Order> orders = [];
      List<models.Order> remoteOrders = [];
      List<MenuItem> menuItems = [];
      RestaurantSettings? settings;

      try {
        orders = await _firestoreService.getOrders(branchId);
        print('📦 Fetched ${orders.length} orders');
      } catch (e) {
        print('❌ Error fetching orders: $e');
      }

      try {
        remoteOrders = await _firestoreService.getRemoteOrders(branchId);
        print('📦 Fetched ${remoteOrders.length} remote orders');
      } catch (e) {
        print('❌ Error fetching remote orders: $e');
      }

      try {
        menuItems = await _firestoreService.getMenuItems(branchId);
        print('🍽️ Fetched ${menuItems.length} menu items');
      } catch (e) {
        print('❌ Error fetching menu items: $e');
      }

      // Get settings
      try {
        if (branchId != null) {
          settings = await _firestoreService.getSettings(branchId);
          print('⚙️ Fetched settings for branch $branchId');
        } else {
          final mainBranch = await _firestoreService.getMainBranch();
          print('🏢 Main branch: ${mainBranch?.name} (${mainBranch?.id})');
          if (mainBranch != null) {
            settings = await _firestoreService.getSettings(mainBranch.id);
            print('⚙️ Fetched settings for main branch');
          }
        }
      } catch (e) {
        print('❌ Error fetching settings: $e');
      }

      setState(() {
        _completedOrders = [...orders, ...remoteOrders]
            .where((o) => o.status == 'completed')
            .toList();
        _menuItems = menuItems;
        _settings = settings;
        _isLoading = false;
      });
      
      print('✅ Data load complete. Completed orders: ${_completedOrders.length}');
    } catch (e) {
      print('❌ Fatal error in _loadData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _calculateStats() {
    final totalRevenue = _completedOrders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final totalOrders = _completedOrders.length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    // Calculate most ordered item
    final itemCounts = <String, int>{};
    for (final order in _completedOrders) {
      for (final item in order.items) {
        if (item.status != 'cancelled') {
          itemCounts[item.name] = (itemCounts[item.name] ?? 0) + item.quantity;
        }
      }
    }

    final topItem = itemCounts.entries.isEmpty
        ? null
        : itemCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'avgOrderValue': avgOrderValue,
      'topItem': topItem?.key ?? 'N/A',
      'topItemCount': topItem?.value ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final stats = _calculateStats();
    final currencySymbol = _settings?.currencySymbol ?? '\$';
    final decimalPlaces = _settings?.currencyDecimalPlaces ?? 2;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome, ${user?.username ?? "Admin"}!',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            if (_isGlobalAdmin && _selectedBranchId != null)
              Text(
                _branches.firstWhere((b) => b.id == _selectedBranchId, orElse: () => Branch(id: '', name: 'Unknown', isMain: false, currencySymbol: r'$', currencyDecimalPlaces: 2, timezone: 'Asia/Kolkata')).name,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
          ],
        ),
        actions: [
          // Branch Selector for Global Admins
          if (_isGlobalAdmin && _branches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<String?>(
                value: _selectedBranchId,
                hint: const Text('All Branches', style: TextStyle(fontSize: 14)),
                icon: const Icon(Icons.arrow_drop_down),
                underline: Container(),
                dropdownColor: Theme.of(context).cardColor,
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 16, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        const Text('All Branches'),
                      ],
                    ),
                  ),
                  ..._branches.map((branch) {
                    return DropdownMenuItem<String?>(
                      value: branch.id,
                      child: Row(
                        children: [
                          Icon(
                            branch.isMain ? Icons.home : Icons.store,
                            size: 16,
                            color: branch.isMain ? AppColors.primaryRed : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(branch.name),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBranchId = newValue;
                  });
                  _loadData(); // Reload data for selected branch
                },
              ),
            ),
          const ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch Indicator for Global Admins
                    if (_isGlobalAdmin)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedBranchId == null ? Icons.business : Icons.store,
                              color: AppColors.primaryRed,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedBranchId == null
                                    ? 'Viewing: All Branches (Combined Data)'
                                    : 'Viewing: ${_branches.firstWhere((b) => b.id == _selectedBranchId, orElse: () => Branch(id: '', name: 'Selected Branch', isMain: false, currencySymbol: r'$', currencyDecimalPlaces: 2, timezone: 'Asia/Kolkata')).name}',
                                style: TextStyle(
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Total Revenue',
                          '$currencySymbol${stats['totalRevenue'].toStringAsFixed(decimalPlaces)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Total Orders',
                          '${stats['totalOrders']}',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Avg Order Value',
                          '$currencySymbol${stats['avgOrderValue'].toStringAsFixed(decimalPlaces)}',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Top Item',
                          stats['topItem'],
                          Icons.star,
                          AppColors.primaryRed,
                          subtitle: '${stats['topItemCount']} sold',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (!user!.isKitchen)
                          _buildActionButton(
                            'Menu Management',
                            Icons.restaurant_menu,
                            () => Navigator.pushNamed(context, '/menu'),
                          ),
                        _buildActionButton(
                          'Sales Report',
                          Icons.bar_chart,
                          () => Navigator.pushNamed(context, '/reports'),
                        ),
                        if (!user!.isKitchen)
                          _buildActionButton(
                            'Kitchen View',
                            Icons.restaurant_menu,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KitchenDashboardScreen(),
                                ),
                              );
                            },
                          ),
                        _buildActionButton(
                          'Refresh Data',
                          Icons.refresh,
                          _loadData,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontFamily: 'Poppins')),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
