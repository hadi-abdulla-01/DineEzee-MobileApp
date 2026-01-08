import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/app_colors.dart';
import '../../services/firebase_config_service.dart';
import '../../main.dart';

class RestaurantSetupScreen extends StatefulWidget {
  const RestaurantSetupScreen({super.key});

  @override
  State<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends State<RestaurantSetupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Replace with your actual API endpoint
  static const String API_ENDPOINT = 'https://yourdomain.com/api/restaurant/validate';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a restaurant code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Validating code: $code');
      
      // Temporary: Bypass for testing
      if (code == 'TEST') {
        // Imitate API response delay
        await Future.delayed(const Duration(seconds: 1));
        
        // Save using the default android config from firebase_options.dart
        await FirebaseConfigService.saveRestaurantConfig(
          code: code,
          restaurantId: 'dineeasee-restaurant', // Use your existing data
          restaurantName: 'Test Restaurant',
          firebaseConfig: {
            'apiKey': 'AIzaSyDS8uv1vEpTAe17Q7IufHK4PdcwsOVkKEo',
            'appId': '1:367695331152:android:9c1d6253a9f95be7e0f655',
            'messagingSenderId': '367695331152',
            'projectId': 'dineezee-deploy-81752760-55669',
            'storageBucket': 'dineezee-deploy-81752760-55669.firebasestorage.app',
            // Add authDomain if needed, usually projectId.firebaseapp.com
             'authDomain': 'dineezee-deploy-81752760-55669.firebaseapp.com',
          },
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected to Test Restaurant'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
            MyApp.restartApp(context);
        }
        return;
      }
      
      // Call your backend API
      final response = await http.post(
        Uri.parse(API_ENDPOINT),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          // Save restaurant configuration
          await FirebaseConfigService.saveRestaurantConfig(
            code: code,
            restaurantId: data['restaurantId'] as String,
            restaurantName: data['restaurantName'] as String,
            firebaseConfig: data['firebaseConfig'] as Map<String, dynamic>,
          );
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Connected to ${data['restaurantName']}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            // Restart app to initialize Firebase with new config
            Navigator.of(context).popUntil((route) => route.isFirst);
            MyApp.restartApp(context);
          }
        } else {
          setState(() => _errorMessage = data['message'] ?? 'Invalid code');
        }
      } else if (response.statusCode == 404) {
        setState(() => _errorMessage = 'Invalid restaurant code');
      } else if (response.statusCode == 403) {
        setState(() => _errorMessage = 'This code has been deactivated');
      } else {
        setState(() => _errorMessage = 'Server error. Please try again later.');
      }
    } catch (e) {
      print('❌ Error validating code: $e');
      setState(() {
        if (e.toString().contains('timeout')) {
          _errorMessage = 'Connection timeout. Please check your internet.';
        } else if (e.toString().contains('SocketException')) {
          _errorMessage = 'No internet connection';
        } else {
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Need Help?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Contact your restaurant administrator to get your unique restaurant code.\n\n'
          'If you\'re setting up a new restaurant, please visit our website to register.\n\n'
          'Each restaurant has a unique code that connects the app to your restaurant\'s data.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: AppColors.primaryRed,
              ),
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Welcome to DineEasy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Enter your restaurant code to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 48),
              
              // Code Input
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'ENTER CODE',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    letterSpacing: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                  ),
                  errorText: _errorMessage,
                  errorMaxLines: 3,
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                ),
                onSubmitted: (_) => _validateCode(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Help Button
              TextButton.icon(
                onPressed: _showHelpDialog,
                icon: const Icon(Icons.help_outline),
                label: const Text(
                  'Don\'t have a code?',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryYellow.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your restaurant code is provided by your administrator',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
