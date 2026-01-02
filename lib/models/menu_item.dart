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
    // Web app uses 'availableSessions', mobile app uses 'sessionIds'
    // Check both for compatibility
    List<String> sessions = [];
    if (data['availableSessions'] != null) {
      sessions = List<String>.from(data['availableSessions']);
    } else if (data['sessionIds'] != null) {
      sessions = List<String>.from(data['sessionIds']);
    }
    
    // Web app uses 'imageId' (base64), mobile app uses 'imageUrl' (Firebase Storage URL)
    // Prefer imageUrl, fallback to imageId
    String? imageSource = data['imageUrl'];
    if (imageSource == null || imageSource.isEmpty) {
      imageSource = data['imageId']; // Use base64 from web app
    }
    
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      imageUrl: imageSource,
      sessionIds: sessions,
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
      'imageId': imageUrl, // Web app uses imageId field
      'availableSessions': sessionIds, // Use web app field name
      'isAvailable': isAvailable,
      'branchId': branchId,
    };
  }
}
