import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  print('🚀 Starting DineEasy app...');
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');
  
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
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    // Now we can safely access Provider in initState
    _initFuture = Future.microtask(() async {
      final authProvider = context.read<AuthProvider>();
      await authProvider.restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('📱 Building MyApp widget...');
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, _) {
        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            // Show loading while restoring session
            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading...'),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Show main app after session restored
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
                '/dashboard': (context) {
                  print('📊 Navigating to DashboardScreen...');
                  return const DashboardScreen();
                },
                '/kitchen': (context) {
                  print('🍳 Navigating to KitchenDashboardScreen...');
                  return const KitchenDashboardScreen();
                },
                '/menu': (context) {
                  print('🍽️ Navigating to MenuManagementScreen...');
                  return const MenuManagementScreen();
                },
                '/settings': (context) {
                  print('⚙️ Navigating to SettingsScreen...');
                  return const SettingsScreen();
                },
                '/reports': (context) {
                  print('📈 Navigating to SalesReportScreen...');
                  return const SalesReportScreen();
                },
                '/sales-history': (context) {
                  print('📋 Navigating to SalesHistoryScreen...');
                  return const SalesHistoryScreen();
                },
                '/users': (context) {
                  print('👥 Navigating to UserManagementScreen...');
                  return const UserManagementScreen();
                },
                '/tables': (context) {
                  print('🍽️ Navigating to TableManagementScreen...');
                  return const TableManagementScreen();
                },
                '/settings/invoice': (context) {
                  print('🧾 Navigating to InvoiceSettingsScreen...');
                  return const InvoiceSettingsScreen();
                },
                '/settings/printing': (context) {
                  print('🖨️ Navigating to PrintingSettingsScreen...');
                  return const PrintingSettingsScreen();
                },
              },
            );
          },
        );
      },
    );
  }
}
