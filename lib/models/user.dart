class KitchenUser {
  final String id;
  final String username;
  final String password;
  final String role; // 'Admin', 'Manager', 'Server', 'Kitchen'
  final String? branchId;
  final List<String> categories;
  final Map<String, Map<String, bool>> permissions;

  KitchenUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.branchId,
    this.categories = const [],
    this.permissions = const {},
  });

  factory KitchenUser.fromFirestore(String id, Map<String, dynamic> data) {
    // Parse categories
    List<String> categoriesList = [];
    if (data['categories'] != null) {
      categoriesList = List<String>.from(data['categories']);
    }

    // Parse permissions
    Map<String, Map<String, bool>> permissionsMap = {};
    if (data['permissions'] != null) {
      final permsData = data['permissions'] as Map<String, dynamic>;
      permsData.forEach((key, value) {
        if (value is Map) {
          permissionsMap[key] = Map<String, bool>.from(value as Map);
        }
      });
    }

    return KitchenUser(
      id: id,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'Kitchen',
      branchId: data['branchId'],
      categories: categoriesList,
      permissions: permissionsMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'branchId': branchId,
      'categories': categories,
      'permissions': permissions,
    };
  }

  bool get isAdmin => role == 'Admin';
  bool get isManager => role == 'Manager';
  bool get isKitchen => role == 'Kitchen';
  bool get isServer => role == 'Server';
}
