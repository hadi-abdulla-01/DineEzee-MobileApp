import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  KitchenUser? _user;
  bool _isLoading = false;
  String? _error;

  KitchenUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _auth.currentUser != null;

  /// Login with email and password using Firebase Auth
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔑 Attempting Firebase Auth login for: $email');
      
      // Extract restaurant ID from email (format: username@restaurantid.dineezee)
      final restaurantId = _extractRestaurantIdFromEmail(email);
      if (restaurantId == null) {
        throw 'Invalid email format. Expected: username@restaurantid.dineezee';
      }
      
      print('🏢 Extracted restaurant ID: $restaurantId');
      
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Authentication failed - no user returned';
      }

      print('✅ Firebase Auth successful, fetching user data from Firestore...');

      // Save restaurant ID to config for future use
      await _saveRestaurantId(restaurantId);

      // Get user data from Firestore using the authenticated email
      final userData = await _firestoreService.getUserByEmail(email);

      if (userData == null) {
        // Sign out from Firebase Auth if user not found in Firestore
        await _auth.signOut();
        throw 'User data not found in database';
      }

      print('✅ User data loaded: ${userData.username} (${userData.role})');
      print('🏢 Branch ID: ${userData.branchId ?? "Global Admin"}');

      _user = userData;
      await _saveSession(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code}');
      String errorMessage = 'Login failed';
      
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Extract restaurant ID from email
  /// Format: username@restaurantid.dineezee
  String? _extractRestaurantIdFromEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return null;
      
      final domainParts = parts[1].split('.');
      if (domainParts.length < 2) return null;
      
      // Check if domain ends with .dineezee
      if (domainParts.last != 'dineezee') return null;
      
      // Restaurant ID is the part before .dineezee
      return domainParts.first;
    } catch (e) {
      print('❌ Error extracting restaurant ID: $e');
      return null;
    }
  }

  /// Save restaurant ID to SharedPreferences
  Future<void> _saveRestaurantId(String restaurantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('restaurant_id', restaurantId);
      print('✅ Restaurant ID saved: $restaurantId');
    } catch (e) {
      print('❌ Error saving restaurant ID: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _user = null;
      _error = null;
      await _clearSession();
      notifyListeners();
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Save session to local storage
  Future<void> _saveSession(KitchenUser user) async {
    try {
      print('💾 Saving session for ${user.username}...');
      
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('userId', user.id);
      await prefs.setString('username', user.username);
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('role', user.role);
      
      if (user.branchId != null) {
        await prefs.setString('branchId', user.branchId!);
      }
      
      print('✅ Session saved successfully');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  /// Restore session from Firebase Auth and local storage
  Future<void> restoreSession() async {
    try {
      print('🔄 Attempting to restore session...');
      
      // Check if user is still signed in with Firebase Auth
      final firebaseUser = _auth.currentUser;
      
      if (firebaseUser == null) {
        print('ℹ️ No Firebase Auth session found');
        await _clearSession();
        return;
      }

      print('✅ Firebase Auth session found for: ${firebaseUser.email}');

      // Try to get user data from Firestore
      if (firebaseUser.email != null) {
        final userData = await _firestoreService.getUserByEmail(firebaseUser.email!);
        
        if (userData != null) {
          _user = userData;
          await _saveSession(userData);
          notifyListeners();
          print('✅ Session restored for ${userData.username}');
          return;
        }
      }

      // Fallback to SharedPreferences if Firestore fetch fails
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final username = prefs.getString('username');
      final email = prefs.getString('email');
      final role = prefs.getString('role');
      final branchId = prefs.getString('branchId');
      
      if (userId != null && username != null && role != null) {
        _user = KitchenUser(
          id: userId,
          username: username,
          email: email,
          password: '', // Don't store password
          role: role,
          branchId: branchId,
        );
        notifyListeners();
        print('✅ Session restored from cache for $username');
      } else {
        print('⚠️ Incomplete session data, signing out');
        await logout();
      }
    } catch (e) {
      print('❌ Error restoring session: $e');
      await logout();
    }
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('role');
      await prefs.remove('branchId');
      print('✅ Session cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }
}
