import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as models;
import '../models/menu_item.dart';
import '../models/settings.dart';
import '../models/user.dart';
import '../models/table.dart';
import '../models/branch.dart';
import '../models/category.dart';

class FirestoreService {
  static const String RESTAURANT_ID = 'dineeasee-restaurant';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== CATEGORIES ==========

  /// Add category (web app format: array in branch document)
  Future<void> addCategory(String branchId, String categoryName) async {
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<String> categories = List<String>.from(branchData['menuCategories'] ?? []);
    
    if (categories.contains(categoryName)) {
      throw Exception('Category already exists');
    }
    
    categories.add(categoryName);
    await branchRef.update({'menuCategories': categories});
    print('✅ Added category: $categoryName');
  }

  /// Update category (web app format: array in branch document)
  Future<void> updateCategory(String branchId, String oldName, String newName) async {
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<String> categories = List<String>.from(branchData['menuCategories'] ?? []);
    final index = categories.indexOf(oldName);
    
    if (index != -1) {
      categories[index] = newName;
      await branchRef.update({'menuCategories': categories});
      print('✅ Updated category: $oldName -> $newName');
    }
  }

  /// Delete category (web app format: array in branch document)
  Future<void> deleteCategory(String branchId, String categoryName) async {
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<String> categories = List<String>.from(branchData['menuCategories'] ?? []);
    categories.remove(categoryName);
    
    await branchRef.update({'menuCategories': categories});
    print('✅ Deleted category: $categoryName');
  }

  /// Reorder categories (web app format: array in branch document)
  Future<void> reorderCategories(String branchId, List<String> newOrder) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .update({'menuCategories': newOrder});
    print('✅ Reordered categories');
  }

  // ========== ORDERS ==========

  /// Get all orders for a specific branch (or all if branchId is null)
  Future<List<models.Order>> getOrders(String? branchId) async {
    Query query = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('orders');

    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => models.Order.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get active orders (received, preparing, ready) for kitchen view
  Future<List<models.Order>> getActiveOrders(String branchId) async {
    try {
      final snapshot = await _db
          .collection('restaurants')
          .doc(RESTAURANT_ID)
          .collection('orders')
          .where('branchId', isEqualTo: branchId)
          .where('status', whereIn: ['received', 'preparing', 'ready'])
          .get(const GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => models.Order.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('⚠️ Error fetching active orders from server, using cache: $e');
      final snapshot = await _db
          .collection('restaurants')
          .doc(RESTAURANT_ID)
          .collection('orders')
          .where('branchId', isEqualTo: branchId)
          .where('status', whereIn: ['received', 'preparing', 'ready'])
          .get();

      return snapshot.docs
          .map((doc) => models.Order.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    }
  }

  /// Get remote orders (online/take-away)
  Future<List<models.Order>> getRemoteOrders(String? branchId) async {
    Query query = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('remoteOrders');

    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => models.Order.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  /// Update order item ready status
  Future<void> updateOrderItemReady(String orderId, String orderItemId, bool isReady) async {
    final orderDoc = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists) return;

    final data = orderDoc.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    final itemIndex = items.indexWhere((item) => item['orderItemId'] == orderItemId);
    if (itemIndex != -1) {
      items[itemIndex]['isReady'] = isReady;
      await orderDoc.reference.update({'items': items});
    }
  }

  /// Cancel order item
  Future<void> cancelOrderItem(String orderId, String orderItemId) async {
    final orderDoc = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists) return;

    final data = orderDoc.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    final itemIndex = items.indexWhere((item) => item['orderItemId'] == orderItemId);
    if (itemIndex != -1) {
      items[itemIndex]['status'] = 'cancelled';
      await orderDoc.reference.update({'items': items});
    }
  }

  // ========== MENU ITEMS ==========

  /// Get all menu items for a branch
  Future<List<MenuItem>> getMenuItems(String? branchId) async {
    Query query = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('menuItems');

    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MenuItem.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Add new menu item
  Future<String> addMenuItem(MenuItem item) async {
    final docRef = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('menuItems')
        .add(item.toMap());
    return docRef.id;
  }

  /// Update menu item
  Future<void> updateMenuItem(String itemId, MenuItem item) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('menuItems')
        .doc(itemId)
        .update(item.toMap());
  }

  /// Delete menu item
  Future<void> deleteMenuItem(String itemId) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('menuItems')
        .doc(itemId)
        .delete();
  }

  // ========== SETTINGS ==========

  /// Get settings for a specific branch
  Future<RestaurantSettings?> getSettings(String branchId) async {
    try {
      // Try to get from server first to ensure fresh data
      try {
        // Get settings from settings/general subdocument
        final settingsDoc = await _db
            .collection('restaurants')
            .doc(RESTAURANT_ID)
            .collection('branches')
            .doc(branchId)
            .collection('settings')
            .doc('general')
            .get(const GetOptions(source: Source.server));

        // Also get branch document for mealSessions (stored at branch level in web app)
        final branchDoc = await _db
            .collection('restaurants')
            .doc(RESTAURANT_ID)
            .collection('branches')
            .doc(branchId)
            .get(const GetOptions(source: Source.server));

        return _processSettingsData(branchId, settingsDoc, branchDoc);
      } catch (e) {
        print('⚠️ Error fetching from server, falling back to cache: $e');
        // Fallback to cache/default if server fails
         final settingsDoc = await _db
            .collection('restaurants')
            .doc(RESTAURANT_ID)
            .collection('branches')
            .doc(branchId)
            .collection('settings')
            .doc('general')
            .get();

        final branchDoc = await _db
            .collection('restaurants')
            .doc(RESTAURANT_ID)
            .collection('branches')
            .doc(branchId)
            .get();
            
        return _processSettingsData(branchId, settingsDoc, branchDoc);
      }
    } catch (e) {
      print('❌ Error loading settings for branch $branchId: $e');
      return null;
    }
  }

  Future<RestaurantSettings?> _processSettingsData(
      String branchId, 
      DocumentSnapshot settingsDoc, 
      DocumentSnapshot branchDoc
  ) async {
      Map<String, dynamic> settingsData = {};
      
      if (settingsDoc.exists && settingsDoc.data() != null) {
        settingsData = Map<String, dynamic>.from(settingsDoc.data() as Map<String, dynamic>);
        print('✅ Found settings subdocument');
      }
      
      if (branchDoc.exists && branchDoc.data() != null) {
        final branchData = branchDoc.data() as Map<String, dynamic>;
        print('✅ Found branch document');
        
        // Merge mealSessions from branch document if not in settings
        if (branchData['mealSessions'] != null) {
          settingsData['mealSessions'] = branchData['mealSessions'];
          print('✅ Using mealSessions from branch document');
        }
        
        // Merge menuCategories from branch document if not in settings
        if (branchData['menuCategories'] != null) {
          settingsData['menuCategories'] = branchData['menuCategories'];
        } else {
          print('⚠️ menuCategories not found in branch document, initializing defaults');
          // Initialize with default categories (matching web app defaults)
          final defaultCategories = ['Meals', 'Snacks', 'Beverages', 'Desserts'];
          settingsData['menuCategories'] = defaultCategories;
        }
        
        // Also get other fields from branch if not in settings
        settingsData['currencySymbol'] ??= branchData['currencySymbol'];
        settingsData['currencyDecimalPlaces'] ??= branchData['currencyDecimalPlaces'];
        settingsData['timezone'] ??= branchData['timezone'];
        settingsData['restaurantName'] ??= branchData['restaurantName'];
        settingsData['restaurantAddress'] ??= branchData['restaurantAddress'];
      }

      if (settingsData.isEmpty) {
        print('⚠️ Settings not found for branch: $branchId, using defaults');
        return null;
      }

      return RestaurantSettings.fromMap(settingsData);
  }

  /// Update settings (creates if doesn't exist)
  Future<void> updateSettings(String branchId, Map<String, dynamic> updates) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .collection('settings')
        .doc('general')
        .set(updates, SetOptions(merge: true));
  }

  // ========== MEAL SESSIONS ==========

  /// Add meal session (web app format: array in branch document)
  Future<String> addMealSession(String branchId, MealSession session) async {
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<dynamic> sessions = List.from(branchData['mealSessions'] ?? []);
    sessions.add(session.toMap());
    
    await branchRef.update({'mealSessions': sessions});
    return session.id;
  }

  /// Update meal session (web app format: array in branch document)
  Future<void> updateMealSession(String branchId, String sessionId, MealSession session) async {
    print('🔄 Updating session: $sessionId in branch: $branchId');
    
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<dynamic> sessions = List.from(branchData['mealSessions'] ?? []);
    print('📋 Current sessions count: ${sessions.length}');
    
    final index = sessions.indexWhere((s) => s['id'] == sessionId);
    print('📋 Found session at index: $index');
    
    if (index != -1) {
      print('✅ Updating session at index $index');
      sessions[index] = session.toMap();
      await branchRef.update({'mealSessions': sessions});
      print('✅ Session updated successfully');
    } else {
      print('❌ Session not found with ID: $sessionId');
      print('📋 Available session IDs: ${sessions.map((s) => s['id']).toList()}');
    }
  }

  /// Update meal session by index (for sessions without IDs)
  Future<void> updateMealSessionByIndex(String branchId, int index, MealSession session) async {
    print('🔄 Updating session by index: $index in branch: $branchId');
    
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<dynamic> sessions = List.from(branchData['mealSessions'] ?? []);
    
    if (index >= 0 && index < sessions.length) {
      print('✅ Updating session at index $index');
      sessions[index] = session.toMap();
      await branchRef.update({'mealSessions': sessions});
      print('✅ Session updated successfully');
    } else {
      print('❌ Invalid index: $index (total sessions: ${sessions.length})');
    }
  }

  /// Delete meal session (web app format: array in branch document)
  Future<void> deleteMealSession(String branchId, String sessionId) async {
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);

    final branchDoc = await branchRef.get();
    final branchData = branchDoc.data() ?? {};
    
    List<dynamic> sessions = List.from(branchData['mealSessions'] ?? []);
    sessions.removeWhere((s) => s['id'] == sessionId);
    
    await branchRef.update({'mealSessions': sessions});
  }

  /// Update manual session override
  Future<void> updateManualSessionOverride(
      String branchId, bool enabled, String? sessionId) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .collection('settings')
        .doc('general')
        .update({
      'manualSessionOverride': {
        'enabled': enabled,
        'sessionId': sessionId,
      },
    });
  }

  // ========== USERS ==========

  /// Get all kitchen users
  Future<List<KitchenUser>> getKitchenUsers() async {
    final snapshot = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('kitchenUsers')
        .get();

    return snapshot.docs
        .map((doc) => KitchenUser.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get user by username
  Future<KitchenUser?> getUserByUsername(String username) async {
    final snapshot = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('kitchenUsers')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return KitchenUser.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Add new user
  Future<String> addUser(KitchenUser user) async {
    final docRef = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('kitchenUsers')
        .add(user.toMap());
    return docRef.id;
  }

  /// Update user
  Future<void> updateUser(String userId, KitchenUser user) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('kitchenUsers')
        .doc(userId)
        .update(user.toMap());
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('kitchenUsers')
        .doc(userId)
        .delete();
  }

  // ========== TABLES ==========

  /// Get all tables for a branch
  Future<List<RestaurantTable>> getTables(String? branchId) async {
    Query query = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('tables');

    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => RestaurantTable.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get table by ID
  Future<RestaurantTable?> getTableById(String tableId) async {
    final doc = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('tables')
        .doc(tableId)
        .get();

    if (!doc.exists) return null;
    return RestaurantTable.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Add new table
  Future<String> addTable(RestaurantTable table) async {
    final docRef = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('tables')
        .add(table.toMap());
    return docRef.id;
  }

  /// Update table
  Future<void> updateTable(String tableId, RestaurantTable table) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('tables')
        .doc(tableId)
        .update(table.toMap());
  }

  /// Delete table
  Future<void> deleteTable(String tableId) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('tables')
        .doc(tableId)
        .delete();
  }

  // ========== BRANCHES ==========

  /// Get all branches
  Future<List<Branch>> getBranches() async {
    final snapshot = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .get();

    return snapshot.docs
        .map((doc) => Branch.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get main branch
  Future<Branch?> getMainBranch() async {
    final snapshot = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .where('isMain', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return Branch.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Get branch by ID
  Future<Branch?> getBranchById(String branchId) async {
    final doc = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .get();

    if (!doc.exists) return null;
    return Branch.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Add new branch
  Future<String> addBranch(String name, bool isMain) async {
    // If setting as main, unset other main branches first
    if (isMain) {
      final mainBranches = await _db
          .collection('restaurants')
          .doc(RESTAURANT_ID)
          .collection('branches')
          .where('isMain', isEqualTo: true)
          .get();

      final batch = _db.batch();
      for (var doc in mainBranches.docs) {
        batch.update(doc.reference, {'isMain': false});
      }
      await batch.commit();
    }

    final branchData = {
      'name': name,
      'isMain': isMain,
      'restaurantName': name,
      'restaurantAddress': '123 Foodie Lane, Gourmet City',
      'currencySymbol': '\$',
      'currencyDecimalPlaces': 2,
      'timezone': 'Asia/Kolkata',
      'menuCategories': ['Meals', 'Snacks', 'Beverages', 'Desserts'],
    };

    final docRef = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .add(branchData);

    print('✅ Branch added: $name (${docRef.id})');
    return docRef.id;
  }

  /// Delete branch
  Future<void> deleteBranch(String branchId) async {
    // Check if it's the main branch
    final branch = await getBranchById(branchId);
    if (branch?.isMain == true) {
      throw Exception('Cannot delete the main branch');
    }

    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .delete();

    print('✅ Branch deleted: $branchId');
  }

  /// Set branch as main
  Future<void> setMainBranch(String branchId) async {
    // Unset all other main branches
    final mainBranches = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .where('isMain', isEqualTo: true)
        .get();

    final batch = _db.batch();
    for (var doc in mainBranches.docs) {
      batch.update(doc.reference, {'isMain': false});
    }

    // Set the new main branch
    final branchRef = _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId);
    batch.update(branchRef, {'isMain': true});

    await batch.commit();
    print('✅ Main branch set: $branchId');
  }

  /// Update branch details (name, address, etc.)
  Future<void> updateBranchDetails(String branchId, Map<String, dynamic> updates) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .update(updates);

    print('✅ Branch details updated: $branchId');
  }

  /// Get global restaurant details
  Future<Map<String, dynamic>?> getRestaurantDetails() async {
    try {
      final doc = await _db
          .collection('restaurants')
          .doc(RESTAURANT_ID)
          .get();

      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? 'DineEZee',
        'address': data['address'] ?? '123 Foodie Lane, Gourmet City',
      };
    } catch (e) {
      print('❌ Error fetching restaurant details: $e');
      return null;
    }
  }

  /// Update global restaurant details
  Future<void> updateRestaurantDetails(String name, String address) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .update({
      'name': name,
      'address': address,
    });

    print('✅ Global restaurant details updated');
  }

  // ========== CATEGORIES ==========

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final snapshot = await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('categories')
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => Category.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ========== INVOICE & PRINT SETTINGS ==========

  /// Update invoice settings for a branch
  Future<void> updateInvoiceSettings(String branchId, Map<String, dynamic> invoiceSettings) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .update({'invoiceSettings': invoiceSettings});

    print('✅ Invoice settings updated for branch: $branchId');
  }

  /// Update print settings for a branch
  Future<void> updatePrintSettings(String branchId, Map<String, dynamic> printSettings) async {
    await _db
        .collection('restaurants')
        .doc(RESTAURANT_ID)
        .collection('branches')
        .doc(branchId)
        .update({'printSettings': printSettings});

    print('✅ Print settings updated for branch: $branchId');
  }

}
