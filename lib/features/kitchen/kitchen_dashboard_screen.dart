import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/order.dart' as models;
import '../../models/settings.dart';
import '../../models/table.dart';
import 'package:intl/intl.dart';
import '../../widgets/theme_toggle.dart';
import '../../core/app_colors.dart';
import '../../widgets/app_drawer.dart';

class KitchenDashboardScreen extends StatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  List<models.Order> _activeOrders = [];
  RestaurantSettings? _settings;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final branchId = user?.branchId;

      if (branchId == null) {
        final mainBranch = await _firestoreService.getMainBranch();
        if (mainBranch == null) return;
        
        final orders = await _firestoreService.getActiveOrders(mainBranch.id);
        final settings = await _firestoreService.getSettings(mainBranch.id);
        
        if (mounted) {
          setState(() {
            _activeOrders = orders;
            _settings = settings;
            _isLoading = false;
          });
        }
      } else {
        final orders = await _firestoreService.getActiveOrders(branchId);
        final settings = await _firestoreService.getSettings(branchId);
        
        if (mounted) {
          setState(() {
            _activeOrders = orders;
            _settings = settings;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestoreService.updateOrderStatus(orderId, newStatus);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

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
        title: Text(
          'Kitchen View',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Orders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New orders will appear here',
                        style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = _activeOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(models.Order order) {
    final currencySymbol = _settings?.currencySymbol ?? '\$';
    final decimalPlaces = _settings?.currencyDecimalPlaces ?? 2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.orderType == 'Dine-in' ? 'Table Order' : order.orderType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.customerName,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
            ),
            const Divider(height: 16),
            
            // Items
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  if (item.status == 'cancelled') return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        if (item.isReady)
                          const Icon(Icons.check_circle, color: Colors.green, size: 16)
                        else
                          const Icon(Icons.circle_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.name}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              decoration: item.isReady ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const Divider(height: 12),
            
            // Total
            Text(
              'Total: $currencySymbol${order.total.toStringAsFixed(decimalPlaces)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleStatusUpdate(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(order.status),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _getButtonText(order.status),
                  style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'received':
        color = Colors.orange;
        break;
      case 'preparing':
        color = Colors.blue;
        break;
      case 'ready':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'received':
        return 'Start Preparing';
      case 'preparing':
        return 'Mark Ready';
      case 'ready':
        return 'Complete';
      default:
        return 'Update';
    }
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'received':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      default:
        return AppColors.primaryRed;
    }
  }

  void _handleStatusUpdate(models.Order order) {
    String newStatus;
    switch (order.status) {
      case 'received':
        newStatus = 'preparing';
        break;
      case 'preparing':
        newStatus = 'ready';
        break;
      case 'ready':
        newStatus = 'completed';
        break;
      default:
        return;
    }
    _updateOrderStatus(order.id, newStatus);
  }
}
