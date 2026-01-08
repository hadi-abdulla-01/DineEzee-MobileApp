import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/kitchen/kitchen_dashboard_screen.dart';
import 'features/menu/menu_management_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/reports/sales_report_screen.dart';
import 'features/reports/sales_history_screen.dart';
import 'features/admin/user_management_screen.dart';
import 'features/admin/table_management_screen.dart';
import 'features/settings/invoice_settings_screen.dart';
import 'features/settings/printing_settings_screen.dart';
import 'services/push_notification_service.dart';

void main() async {
  print('🚀 Starting DineEasy app...');
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            print('🔐 Creating AuthProvider...');
            return AuthProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print('🎨 Creating ThemeProvider...');
            return ThemeProvider();
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.restoreSession();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Starting DineEasy...'),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, _) {
        return MaterialApp(
          title: 'DineEasy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: authProvider.isAuthenticated
              ? const DashboardScreen()
              : const LoginScreen(),
          routes: {
            '/dashboard': (context) => const DashboardScreen(),
            '/kitchen': (context) => const KitchenDashboardScreen(),
            '/menu': (context) => const MenuManagementScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/reports': (context) => const SalesReportScreen(),
            '/sales-history': (context) => const SalesHistoryScreen(),
            '/users': (context) => const UserManagementScreen(),
            '/tables': (context) => const TableManagementScreen(),
            '/settings/invoice': (context) => const InvoiceSettingsScreen(),
            '/settings/printing': (context) => const PrintingSettingsScreen(),
          },
        );
      },
    );
  }
}
