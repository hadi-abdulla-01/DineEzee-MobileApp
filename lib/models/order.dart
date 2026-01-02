class OrderItem {
  final String orderItemId;
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;
  final bool isReady;
  final String status; // 'active' or 'cancelled'
  final String? notes;

  OrderItem({
    required this.orderItemId,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.isReady,
    required this.status,
    this.notes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      orderItemId: map['orderItemId'] ?? '',
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      isReady: map['isReady'] ?? false,
      status: map['status'] ?? 'active',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderItemId': orderItemId,
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'isReady': isReady,
      'status': status,
      'notes': notes,
    };
  }
}

class Order {
  final String id;
  final String orderType; // 'Dine-in', 'Online', 'Take-away'
  final String status; // 'received', 'preparing', 'ready', 'completed', 'cancelled'
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double total;
  final DateTime createdAt;
  final String? tableId;
  final String? notes;
  final String? branchId;

  Order({
    required this.id,
    required this.orderType,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.createdAt,
    this.tableId,
    this.notes,
    this.branchId,
  });

  factory Order.fromFirestore(String id, Map<String, dynamic> data) {
    return Order(
      id: id,
      orderType: data['orderType'] ?? 'Dine-in',
      status: data['status'] ?? 'received',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (data['total'] ?? 0).toDouble(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      tableId: data['tableId'],
      notes: data['notes'],
      branchId: data['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderType': orderType,
      'status': status,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'createdAt': createdAt,
      'tableId': tableId,
      'notes': notes,
      'branchId': branchId,
    };
  }
}
