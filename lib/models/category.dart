class Category {
  final String id;
  final String name;
  final String? icon;
  final int order;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.order,
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'],
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'order': order,
    };
  }
}
