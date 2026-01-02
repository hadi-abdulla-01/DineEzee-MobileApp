import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  KitchenUser? _user;
  bool _isLoading = false;
  String? _error;

  KitchenUser? get user => _user;
  set user(KitchenUser? value) {
    _user = value;
    notifyListeners();
  }
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

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

      _user = user;
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
  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
