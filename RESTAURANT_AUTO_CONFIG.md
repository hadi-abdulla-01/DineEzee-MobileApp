# Flutter App - Automatic Restaurant ID Configuration

## 🎯 **New Simplified Flow**

The Flutter app now **automatically extracts the restaurant ID from the email** during login. No separate restaurant setup is needed!

## 🔐 **How It Works**

### **Email Format**
All users have emails in this format:
```
username@restaurantid.dineezee
```

**Examples:**
- `admin@pizzapalace.dineezee` → Restaurant: `pizzapalace`
- `john@cafedelight.dineezee` → Restaurant: `cafedelight`
- `kitchen1@dineeasee-restaurant.dineezee` → Restaurant: `dineeasee-restaurant`

### **Login Flow**

```
User enters: admin@pizzapalace.dineezee
             ↓
App extracts: restaurantId = "pizzapalace"
             ↓
Saves to config: SharedPreferences['restaurant_id'] = "pizzapalace"
             ↓
Firebase Auth: Authenticates user
             ↓
Firestore: Fetches user data from restaurants/pizzapalace/kitchenUsers
             ↓
Success! User logged in to their restaurant
```

## 🏢 **Multi-Tenancy & Branch Isolation**

### **Global Admin**
- **Email**: `admin@restaurantid.dineezee`
- **Branch ID**: `null` or empty
- **Access**: Can view and manage ALL branches under their restaurant
- **Dashboard**: Shows aggregated data from all branches
- **Settings**: Can configure all branches

### **Branch-Specific User**
- **Email**: `username@restaurantid.dineezee`
- **Branch ID**: Specific branch ID (e.g., `branch_001`)
- **Access**: ONLY their assigned branch
- **Dashboard**: Shows data from their branch only
- **Settings**: Can only modify their branch settings

### **Example Scenarios**

#### Scenario 1: Global Admin Login
```
Email: admin@pizzapalace.dineezee
Password: ********

Result:
✅ Logged into restaurant: pizzapalace
✅ Role: Admin
✅ Branch: Global Admin - All Branches
✅ Can manage: All branches (Main, Downtown, Airport, etc.)
```

#### Scenario 2: Branch Manager Login
```
Email: john@pizzapalace.dineezee
Password: ********

Result:
✅ Logged into restaurant: pizzapalace
✅ Role: Manager
✅ Branch: Downtown Branch
✅ Can manage: Downtown Branch ONLY
```

#### Scenario 3: Kitchen User Login
```
Email: chef1@pizzapalace.dineezee
Password: ********

Result:
✅ Logged into restaurant: pizzapalace
✅ Role: Kitchen
✅ Branch: Airport Branch
✅ Can view: Orders from Airport Branch ONLY
```

## 📱 **User Experience**

### **Login Screen**
1. User opens app
2. Sees login screen with two tabs: **Admin Login** | **Kitchen Login**
3. Enters their **full email** (e.g., `admin@pizzapalace.dineezee`)
4. Enters password
5. Clicks "Log In"

### **What Happens Behind the Scenes**
1. App extracts `pizzapalace` from email
2. Saves restaurant ID to local storage
3. Authenticates with Firebase Auth
4. Fetches user data from `restaurants/pizzapalace/kitchenUsers`
5. Checks user's `branchId`:
   - If `null` or empty → **Global Admin** (all branches)
   - If has value → **Branch User** (specific branch only)
6. Redirects to Dashboard with appropriate data scope

## 🔧 **Technical Implementation**

### **Files Modified**

#### `lib/providers/auth_provider.dart`
```dart
// Extracts restaurant ID from email
String? _extractRestaurantIdFromEmail(String email) {
  // email: admin@pizzapalace.dineezee
  // returns: "pizzapalace"
}

// Saves to SharedPreferences for future use
Future<void> _saveRestaurantId(String restaurantId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('restaurant_id', restaurantId);
}
```

#### `lib/features/auth/login_screen.dart`
```dart
// Accepts email directly (or username for backward compatibility)
Future<void> _handleLogin(String emailOrUsername, String password) {
  String email;
  if (emailOrUsername.contains('@')) {
    email = emailOrUsername; // Already email
  } else {
    // Fallback: convert username to email if restaurant ID exists
    email = '$emailOrUsername@$restaurantId.dineezee';
  }
  // Login with email
}
```

#### `lib/services/firestore_service.dart`
```dart
// Uses restaurant ID from SharedPreferences
Future<String> _getRestaurantId() async {
  final restaurantId = await FirebaseConfigService.getRestaurantId();
  // All queries scoped to: restaurants/{restaurantId}/...
}
```

## 🎨 **UI Updates**

### **Login Screen Hints**
- **Admin Login**: "Email (e.g., admin@restaurant.dineezee)"
- **Kitchen Login**: "Email (e.g., user@restaurant.dineezee)"

### **Success Messages**
```
Welcome admin!
🏢 Restaurant: pizzapalace
🏢 Branch: Global Admin - All Branches
```

or

```
Welcome john!
🏢 Restaurant: pizzapalace
🏢 Branch: Downtown Branch
```

## 🧪 **Testing**

### **Test Case 1: Global Admin**
```
Email: admin@dineeasee-restaurant.dineezee
Password: [your password]

Expected:
✅ Login successful
✅ Restaurant ID saved: dineeasee-restaurant
✅ User role: Admin
✅ Branch ID: null
✅ Dashboard shows: All branches data
```

### **Test Case 2: Branch Manager**
```
Email: adminbranch1@dineeasee-restaurant.dineezee
Password: [your password]

Expected:
✅ Login successful
✅ Restaurant ID saved: dineeasee-restaurant
✅ User role: Admin (or Manager)
✅ Branch ID: [specific branch ID]
✅ Dashboard shows: Only that branch's data
```

### **Test Case 3: Kitchen User**
```
Email: kitchen1@dineeasee-restaurant.dineezee
Password: [your password]

Expected:
✅ Login successful
✅ Restaurant ID saved: dineeasee-restaurant
✅ User role: Kitchen
✅ Branch ID: [specific branch ID]
✅ Kitchen view shows: Only that branch's orders
```

## 🚀 **Running the App**

### **No Setup Required!**
Just run:
```bash
flutter run -d [device]
```

### **First Login**
1. Enter your email: `admin@yourrestaurant.dineezee`
2. Enter your password
3. App automatically configures itself!

### **Subsequent Logins**
- Restaurant ID is already saved
- Can enter just username (app will append saved restaurant domain)
- Or enter full email (recommended)

## 🔄 **Switching Restaurants**

If a user needs to switch to a different restaurant:

1. **Logout** from current session
2. **Login** with new restaurant email
3. App automatically updates restaurant ID

Example:
```
Currently: admin@pizzapalace.dineezee
Logout
Login with: admin@cafedelight.dineezee
Now connected to: cafedelight
```

## 📊 **Data Isolation**

### **Firestore Queries**
All queries are automatically scoped:

```dart
// Global Admin viewing all branches
restaurants/pizzapalace/orders (no branchId filter)

// Branch User viewing their branch
restaurants/pizzapalace/orders?branchId=branch_001
```

### **Real-Time Updates**
- Kitchen users only receive notifications for their branch
- Global admins can see all branch activities
- Branch managers see only their branch metrics

## ⚠️ **Important Notes**

1. **Email is Required**: Users MUST enter their full email on first login
2. **Case Sensitive**: Restaurant IDs are case-sensitive
3. **Format Matters**: Email must be `username@restaurantid.dineezee`
4. **No Setup Screen**: The old restaurant setup screen is no longer needed
5. **Automatic Config**: Restaurant ID is extracted and saved automatically

## 🎯 **Benefits**

✅ **Simpler UX**: No separate setup step
✅ **Automatic**: Restaurant ID extracted from email
✅ **Secure**: Uses Firebase Auth
✅ **Multi-Tenant**: Each restaurant is isolated
✅ **Branch Isolation**: Branch users see only their data
✅ **Flexible**: Global admins can manage all branches

## 📝 **Migration from Old System**

If you had the old username-based system:

**Old Way:**
1. Setup restaurant code
2. Login with username
3. App queries Firestore for username

**New Way:**
1. Login with email
2. App extracts restaurant ID from email
3. App authenticates with Firebase Auth
4. App fetches user data from correct restaurant

**No data migration needed!** Just ensure all users have:
- Email field in Firestore
- Firebase Auth account with same email
