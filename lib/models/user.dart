class KitchenUser {
  final String id;
  final String username;
  final String password;
  final String role; // 'Admin', 'Manager', 'Kitchen'
  final String? branchId;

  KitchenUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.branchId,
  });

  factory KitchenUser.fromFirestore(String id, Map<String, dynamic> data) {
    return KitchenUser(
      id: id,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'Kitchen',
      branchId: data['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'branchId': branchId,
    };
  }

  bool get isAdmin => role == 'Admin';
  bool get isManager => role == 'Manager';
  bool get isKitchen => role == 'Kitchen';
}
