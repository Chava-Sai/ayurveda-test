class Medicine {
  final String id;
  final String name;
  final double price;
  final String quantity;
  final String description;
  final String manufacturer;
  final String category;
  final int stock;
  final String company;

  int? selectedCount = 0;

  Medicine({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    required this.stock,
    required this.manufacturer,
    required this.category,
    required this.company,
    required this.selectedCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'stock': stock,
      'description': description,
      'manufacturer': manufacturer,
      'category': category,
      'company': company,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      stock: map['stock'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? '',
      description: map['description'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      category: map['category'] ?? '',
      company: map['company'] ?? '',
      selectedCount: 0,
    );
  }
}