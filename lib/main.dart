import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/kitchen/kitchen_dashboard_screen.dart';
import 'features/menu/menu_management_screen.dart';
import 'features/settings/settings_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  print('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');
  
  // Initialize Firebase only if not already initialized
  print('🔥 Checking Firebase...');
  try {
    if (Firebase.apps.isEmpty) {
      print('🔥 Initializing Firebase for the first time...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } else {
      print('✅ Firebase already initialized (${Firebase.apps.length} apps), skipping...');
    }
  } catch (e) {
    print('⚠️ Firebase initialization error (likely already initialized): $e');
    // Continue anyway - Firebase is probably already initialized
  }
  
  print('🎨 Starting app...');
  runApp(const MyApp());
  print('✅ App started');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('📱 Building MyApp widget...');
    return MultiProvider(
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DineEasy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) {
                print('🏠 Navigating to LoginScreen...');
                return const LoginScreen();
              },
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
            },
          );
        },
      ),
    );
  }
}
