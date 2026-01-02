import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  KitchenUser? _user;
  bool _isLoading = false;
  String? _error;
  bool _branchIdFixed = false;

  KitchenUser? get user {
    // Auto-fix branchId if null (for existing sessions)
    if (_user != null && !_branchIdFixed && (_user!.branchId == null || _user!.branchId!.isEmpty)) {
      _fixBranchId();
    }
    return _user;
  }
  
  set user(KitchenUser? value) {
    _user = value;
    _branchIdFixed = false;
    notifyListeners();
  }
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Fix null branchId by fetching main branch
  Future<void> _fixBranchId() async {
    if (_branchIdFixed || _user == null) return;
    _branchIdFixed = true;
    
    try {
      print('⚠️ User ${_user!.username} has no branchId, fetching main branch...');
      final mainBranch = await _firestoreService.getMainBranch();
      if (mainBranch != null) {
        print('✅ Setting branchId to main branch: ${mainBranch.id}');
        _user = KitchenUser(
          id: _user!.id,
          username: _user!.username,
          password: _user!.password,
          role: _user!.role,
          branchId: mainBranch.id,
        );
        notifyListeners();
      } else {
        print('❌ No main branch found, user will have null branchId');
      }
    } catch (e) {
      print('❌ Error fixing branchId: $e');
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _firestoreService.getUserByUsername(username);

      if (user == null) {
        _error = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (user.password != password) {
        _error = 'Invalid password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // If user has no branchId (e.g., admin), set it to main branch
      KitchenUser finalUser = user;
      if (user.branchId == null || user.branchId!.isEmpty) {
        print('⚠️ User ${user.username} has no branchId, fetching main branch...');
        final mainBranch = await _firestoreService.getMainBranch();
        if (mainBranch != null) {
          print('✅ Setting branchId to main branch: ${mainBranch.id}');
          finalUser = KitchenUser(
            id: user.id,
            username: user.username,
            password: user.password,
            role: user.role,
            branchId: mainBranch.id,
          );
        } else {
          print('❌ No main branch found, user will have null branchId');
        }
      }

      _user = finalUser;
      await _saveSession(finalUser); // Save session
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  void logout() async {
    _user = null;
    _error = null;
    await _clearSession(); // Clear saved session
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Save session to local storage
  Future<void> _saveSession(KitchenUser user) async {
    try {
      print('💾 Attempting to save session for ${user.username}...');
      print('📋 User data: id=${user.id}, role=${user.role}, branchId=${user.branchId}');
      
      final prefs = await SharedPreferences.getInstance();
      print('✅ Got SharedPreferences instance');
      
      await prefs.setString('userId', user.id);
      print('✅ Saved userId: ${user.id}');
      
      await prefs.setString('username', user.username);
      print('✅ Saved username: ${user.username}');
      
      await prefs.setString('role', user.role);
      print('✅ Saved role: ${user.role}');
      
      if (user.branchId != null) {
        await prefs.setString('branchId', user.branchId!);
        print('✅ Saved branchId: ${user.branchId}');
      } else {
        print('⚠️ branchId is null, not saving');
      }
      
      print('✅ Session saved successfully for ${user.username}');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  /// Restore session from local storage
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        print('🔄 Restoring session for user: $userId');
        final username = prefs.getString('username');
        final role = prefs.getString('role');
        final branchId = prefs.getString('branchId');
        
        if (username != null && role != null) {
          _user = KitchenUser(
            id: userId,
            username: username,
            password: '', // Don't store password
            role: role,
            branchId: branchId,
          );
          
          // Fix branchId if null
          if (_user != null && (_user!.branchId == null || _user!.branchId!.isEmpty)) {
            await _fixBranchId();
          }
          
          notifyListeners();
          print('✅ Session restored for $username');
        }
      } else {
        print('ℹ️ No saved session found');
      }
    } catch (e) {
      print('❌ Error restoring session: $e');
    }
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('role');
      await prefs.remove('branchId');
      print('✅ Session cleared');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }
}
