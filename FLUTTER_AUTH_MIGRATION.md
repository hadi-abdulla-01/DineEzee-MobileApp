# Flutter App Migration Guide - Firebase Authentication

## Overview
The Flutter mobile app has been migrated to use **Firebase Authentication** with email/password, matching the web app's authentication system. This replaces the previous username-based Firestore lookup method.

## Key Changes

### 1. Authentication Flow
**Before:**
- Users logged in with username and password
- App directly queried Firestore for user with matching username
- Password was compared in the app

**After:**
- Users still enter username and password in the UI
- Username is converted to email format: `username@restaurantid.dineezee`
- Firebase Authentication handles login with email/password
- User data is fetched from Firestore after successful authentication

### 2. Email Format
All users now have emails in the format:
- **Regular users**: `username@restaurantid.dineezee`
- **Admin users**: `admin@restaurantid.dineezee`
- **Branch users**: `username@restaurantid.dineezee` (same format)

Example:
- Restaurant ID: `pizzapalace`
- Username: `john`
- Generated Email: `john@pizzapalace.dineezee`

### 3. Files Modified

#### `lib/providers/auth_provider.dart`
- **Complete rewrite** to use `FirebaseAuth`
- `login()` now accepts email instead of username
- Added Firebase Auth error handling
- Session restoration now checks Firebase Auth state first
- Improved error messages for common auth failures

#### `lib/services/firestore_service.dart`
- Added `getUserByEmail()` method
- Kept `getUserByUsername()` for backward compatibility

#### `lib/models/user.dart`
- Added `email` field to `KitchenUser` model
- Added `isGlobalAdmin` getter for role checking
- Updated `fromFirestore()` and `toMap()` to handle email

#### `lib/features/auth/login_screen.dart`
- Updated `_handleLogin()` to:
  - Get restaurant ID from config
  - Convert username to email format
  - Pass email to auth provider
- Added import for `FirebaseConfigService`
- Improved error handling

### 4. Multi-Tenancy Support
The app now fully supports multi-tenancy:
- Restaurant ID is fetched from `FirebaseConfigService`
- All Firestore queries are scoped to the restaurant
- Branch isolation is enforced for non-global admins

### 5. Global Admin Detection
Added `isGlobalAdmin` getter to `KitchenUser`:
```dart
bool get isGlobalAdmin => 
  (role == 'Admin' && (branchId == null || branchId!.isEmpty)) || 
  username.toLowerCase() == 'admin';
```

This matches the web app's logic for identifying global administrators.

## Migration Steps for Existing Users

### For Users Already in Firestore
1. Ensure all users in Firestore have the `email` field populated
2. Email should match the format: `username@restaurantid.dineezee`
3. Users must be created in Firebase Authentication with the same email/password

### For New User Creation
When creating users through the web app:
1. User is created in Firebase Auth with email/password
2. User document is created in Firestore with `email`, `firebaseUid`, etc.
3. Mobile app can now authenticate these users

## Testing Checklist

### Authentication
- [ ] Admin can log in with username (converted to email)
- [ ] Kitchen users can log in with username
- [ ] Manager/Server users can log in
- [ ] Invalid credentials show proper error message
- [ ] Session persists after app restart
- [ ] Logout clears both Firebase Auth and local session

### Multi-Tenancy
- [ ] App uses correct restaurant ID from config
- [ ] Branch-specific users only see their branch data
- [ ] Global admin can see all branches
- [ ] Data queries are properly scoped

### Error Handling
- [ ] "User not found" shows clear message
- [ ] "Wrong password" shows clear message
- [ ] "No restaurant configured" shows when config missing
- [ ] Network errors are handled gracefully

## Troubleshooting

### "No restaurant configured" Error
**Solution**: Ensure `FirebaseConfigService.getRestaurantId()` returns a valid restaurant ID. Check the app's configuration.

### "User data not found in database" Error
**Solution**: 
1. Verify the user exists in Firestore under `restaurants/{restaurantId}/kitchenUsers`
2. Ensure the user document has an `email` field matching the Firebase Auth email

### "Invalid email or password" Error
**Solution**:
1. Check that the user exists in Firebase Authentication
2. Verify the email format is correct: `username@restaurantid.dineezee`
3. Ensure the password matches

### Session Not Restoring
**Solution**:
1. Check that Firebase Auth session is active
2. Verify SharedPreferences has user data
3. Ensure Firestore user document is accessible

## Future Enhancements

### Recommended Improvements
1. **Password Reset**: Implement Firebase Auth password reset flow
2. **Email Verification**: Add email verification for new users
3. **Biometric Auth**: Add fingerprint/face ID support
4. **Multi-Factor Auth**: Add 2FA for admin users
5. **Offline Support**: Improve offline authentication handling

### Branch Filtering UI
Consider adding branch selection UI for global admins in:
- Dashboard
- Kitchen View
- Reports
- User Management

This would match the web app's functionality where global admins can filter by branch.

## Notes

### Backward Compatibility
- The old `getUserByUsername()` method is retained for any legacy code
- Existing session data is migrated during `restoreSession()`
- Password field is still stored in Firestore for reference (though not used for auth)

### Security
- Passwords are now handled by Firebase Auth (more secure)
- Firebase Auth provides built-in protection against brute force attacks
- Session tokens are managed by Firebase SDK

### Performance
- Firebase Auth caching reduces network calls
- Session restoration is faster with Firebase Auth state
- Firestore queries remain efficient with proper indexing

## Support
For issues or questions about the migration, refer to:
- Web app implementation in `src/lib/auth.ts` and `src/app/admin/auth-provider.tsx`
- Firebase Auth documentation: https://firebase.google.com/docs/auth
- Multi-tenancy guide in `MULTI_TENANT_STRUCTURE.md`
