class RestaurantTable {
  final String id;
  final int number;
  final int capacity;
  final String status; // 'Available', 'Occupied', 'Reserved'
  final String? branchId;

  RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    this.branchId,
  });

  factory RestaurantTable.fromFirestore(String id, Map<String, dynamic> data) {
    return RestaurantTable(
      id: id,
      number: data['number'] ?? 0,
      capacity: data['capacity'] ?? 4,
      status: data['status'] ?? 'Available',
      branchId: data['branchId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'capacity': capacity,
      'status': status,
      'branchId': branchId,
    };
  }

  bool get isAvailable => status == 'Available';
  bool get isOccupied => status == 'Occupied';
  bool get isReserved => status == 'Reserved';
}
