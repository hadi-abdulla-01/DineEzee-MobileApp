import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_colors.dart';
import 'theme_toggle.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isKitchen = user?.isKitchen ?? false;

    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primaryYellow,
              child: Icon(
                isKitchen ? Icons.restaurant : Icons.admin_panel_settings,
                size: 40,
                color: AppColors.primaryRed,
              ),
            ),
            accountName: Text(
              user?.username ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            accountEmail: Text(
              user?.role ?? 'Role',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard (Admin/Manager only)
                if (!isKitchen)
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/dashboard',
                  ),

                // Kitchen View
                _buildMenuItem(
                  context,
                  icon: Icons.restaurant_menu,
                  title: 'Kitchen View',
                  route: '/kitchen',
                ),

                // Menu Management (Admin/Manager only)
                if (!isKitchen) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book,
                    title: 'Menu Management',
                    route: '/menu',
                  ),

                  // Sales Report
                  _buildMenuItem(
                    context,
                    icon: Icons.assessment,
                    title: 'Sales Report',
                    route: '/reports',
                  ),

                  // Sales History
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Sales History',
                    route: '/sales-history',
                  ),

                  // User Management
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: 'User Management',
                    route: '/users',
                  ),

                  // Table Management
                  _buildMenuItem(
                    context,
                    icon: Icons.table_restaurant,
                    title: 'Table Management',
                    route: '/tables',
                  ),

                  const Divider(),

                  // Settings
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    route: '/settings',
                  ),
                ],
              ],
            ),
          ),

          // Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? AppColors.primaryRed 
            : (isDark ? Colors.grey[400] : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected 
              ? AppColors.primaryRed 
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryYellow.withOpacity(0.2),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
