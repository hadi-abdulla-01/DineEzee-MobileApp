class Branch {
  final String id;
  final String name;
  final bool isMain;
  final String? restaurantName;
  final String? restaurantAddress;
  final String currencySymbol;
  final int currencyDecimalPlaces;
  final String timezone;

  Branch({
    required this.id,
    required this.name,
    required this.isMain,
    this.restaurantName,
    this.restaurantAddress,
    required this.currencySymbol,
    required this.currencyDecimalPlaces,
    required this.timezone,
  });

  factory Branch.fromFirestore(String id, Map<String, dynamic> data) {
    return Branch(
      id: id,
      name: data['name'] ?? '',
      isMain: data['isMain'] ?? false,
      restaurantName: data['restaurantName'],
      restaurantAddress: data['restaurantAddress'],
      currencySymbol: data['currencySymbol'] ?? '\$',
      currencyDecimalPlaces: data['currencyDecimalPlaces'] ?? 2,
      timezone: data['timezone'] ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isMain': isMain,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'currencySymbol': currencySymbol,
      'currencyDecimalPlaces': currencyDecimalPlaces,
      'timezone': timezone,
    };
  }
}
