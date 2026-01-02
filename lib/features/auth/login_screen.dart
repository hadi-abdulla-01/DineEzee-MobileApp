import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_easy_mobile/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAdmin = true;
  bool _isTransitioning = false;
  double _contentOpacity = 1.0;
  // Controllers for Admin
  final TextEditingController _adminUserCtrl = TextEditingController();
  final TextEditingController _adminPassCtrl = TextEditingController();
  
  // Controllers for Kitchen
  final TextEditingController _kitchenUserCtrl = TextEditingController();
  final TextEditingController _kitchenPassCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _adminUserCtrl.dispose();
    _adminPassCtrl.dispose();
    _kitchenUserCtrl.dispose();
    _kitchenPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String username, String password, bool expectingAdmin) async {
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔑 Attempting login for: $username');
      
      // Call AuthProvider's login method (which saves session)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(username, password);
      
      if (!success) {
        throw authProvider.error ?? 'Login failed';
      }
      
      // Validate role
      final user = authProvider.user;
      if (user == null) {
        throw 'Login failed - no user data';
      }
      
      if (expectingAdmin && user.role == 'Kitchen') {
        authProvider.logout(); // Clear the session
        throw 'Kitchen staff must log in through the kitchen portal.';
      }

      print('✅ Login successful for ${user.username}');

      // Login Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful!')),
      );

      Navigator.of(context).pushReplacementNamed('/dashboard');

    } catch (e) {
      print('❌ Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(), // Force light theme for login screen
      child: Scaffold(
        backgroundColor: AppColors.primaryYellow,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with manual opacity control
            Center(
              child: AnimatedOpacity(
                opacity: _contentOpacity,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isAdmin 
                  ? _buildLoginPanel(
                      key: const ValueKey('AdminLogin'),
                      title: 'Admin Login',
                      usernameHint: 'Your Username',
                      userCtrl: _adminUserCtrl,
                      passCtrl: _adminPassCtrl,
                      isExpectingAdmin: true,
                      switchText: 'Not an admin?',
                      switchActionText: 'Kitchen Login',
                      onSwitch: _switchToKitchen,
                    )
                  : _buildLoginPanel(
                      key: const ValueKey('KitchenLogin'),
                      title: 'Kitchen Login',
                      usernameHint: 'Kitchen User',
                      userCtrl: _kitchenUserCtrl,
                      passCtrl: _kitchenPassCtrl,
                      isExpectingAdmin: false,
                      switchText: 'Not a kitchen user?',
                      switchActionText: 'Admin Login',
                      onSwitch: _switchToAdmin,
                    ),
              ),
            ),
            
            // Sliding maroon overlay
            if (_isTransitioning)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: -1.0, end: 1.0),
                curve: Curves.easeInOutCubic,
                onEnd: () {
                  setState(() {
                    _isTransitioning = false;
                    _contentOpacity = 1.0; // Fade in new content
                  });
                },
                builder: (context, value, child) {
                  return Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(MediaQuery.of(context).size.width * value, 0),
                      child: Container(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      ), // Close Scaffold
    ); // Close Theme
  }

  void _switchToKitchen() {
    // Start both fade out and sliding overlay simultaneously
    setState(() {
      _contentOpacity = 0.0;
      _isTransitioning = true;
    });
    
    // Switch content at midpoint (300ms)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          isAdmin = false;
        });
      }
    });
  }

  void _switchToAdmin() {
    // Start both fade out and sliding overlay simultaneously
    setState(() {
      _contentOpacity = 0.0;
      _isTransitioning = true;
    });
    
    // Switch content at midpoint (300ms)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          isAdmin = true;
        });
      }
    });
  }

  Widget _buildLoginPanel({
    required Key key,
    required String title,
    required String usernameHint,
    required TextEditingController userCtrl,
    required TextEditingController passCtrl,
    required bool isExpectingAdmin,
    required String switchText,
    required String switchActionText,
    required VoidCallback onSwitch,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 40.0), // Match web padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30, // Match web lg:text-[30px]
              fontWeight: FontWeight.w600,
              color: AppColors.primaryRed,
              fontFamily: 'Poppins',
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 40), // Gap 10 in tailwind (40px)

          // Input Fields (No outer card!)
          Column(
            children: [
              _buildInput(hint: usernameHint, icon: Icons.person_outline, controller: userCtrl),
              const SizedBox(height: 24), // Gap 6 in tailwind (24px)
              _buildInput(hint: 'Password', icon: Icons.lock_outline, isPassword: true, controller: passCtrl),
            ],
          ),
          
          const SizedBox(height: 40), // Matches web gap

          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading 
                ? null 
                : () => _handleLogin(userCtrl.text.trim(), passCtrl.text, isExpectingAdmin),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16), // Match web py-3 roughly
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Match web rounded-[8px]
                elevation: 0, // Web has no shadow on button
              ),
              child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text(
                      'Log In', 
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600, 
                        fontSize: 15, // Match web text-[15px]
                        letterSpacing: 0.1
                      )
                    ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                switchText + " ", 
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.primaryRed.withOpacity(0.45), // Match web rgba(203,30,29,0.45)
                  fontSize: 15
                )
              ),
              GestureDetector(
                onTap: onSwitch,
                child: Text(
                  switchActionText, 
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.primaryRed, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w600,
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required String hint, required IconData icon, bool isPassword = false, TextEditingController? controller}) {
    // Matches Web "Wrapper" component
    // bg-white relative rounded-[8px] ... border-[#e0e2e9] border-[1.604px]
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E2E9), width: 1.6),
        boxShadow: [], // Web has no shadow on inputs in mobile view
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased from 12 to 16 for better height
      child: Row(
        children: [
          // Icon (Vector)
          Icon(icon, color: const Color(0xFFADB0CD), size: 18), // Match web fill/stroke #ADB0CD
          const SizedBox(width: 16), // Match web gap-[16px]
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                hintText: hint,
                // Match web text-[#969ab8] text-[14px]
                hintStyle: const TextStyle(color: Color(0xFF969AB8), fontSize: 14, fontFamily: 'Poppins'),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              // Match web text-[#969ab8] text-[14px] (actually input text usually darker, but web sets same class)
              style: const TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
