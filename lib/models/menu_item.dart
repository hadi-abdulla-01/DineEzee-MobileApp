class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? description;
  final String? imageUrl;
  final List<String> sessionIds;
  final bool isAvailable;
  final String? branchId;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.imageUrl,
    required this.sessionIds,
    required this.isAvailable,
    this.branchId,
  });

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> data) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      imageUrl: data['imageUrl'],
      sessionIds: List<String>.from(data['sessionIds'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      branchId: data['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'sessionIds': sessionIds,
      'isAvailable': isAvailable,
      'branchId': branchId,
    };
  }
}
